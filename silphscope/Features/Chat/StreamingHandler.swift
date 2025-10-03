import Foundation
import Swollama

protocol StreamingHandlerDelegate: AnyObject {
    func streamingHandler(_ handler: StreamingHandler, didUpdateContent content: String)
    func streamingHandler(_ handler: StreamingHandler, didCompleteWithContent content: String)
    func streamingHandler(_ handler: StreamingHandler, didFailWithError error: Error)
}

final class StreamingHandler {

    weak var delegate: StreamingHandlerDelegate?

    private var streamBuffer = ""
    private var currentTask: Task<Void, Never>?

    func startStreaming(
        _ stream: AsyncThrowingStream<ChatResponse, Error>
    ) {
        streamBuffer = ""

        currentTask = Task { @MainActor in
            do {
                for try await response in stream {
                    if Task.isCancelled {
                        AppLogger.shared.debug(
                            "Stream cancelled at \(streamBuffer.count) chars",
                            category: .ollama
                        )
                        break
                    }

                    if response.done {
                        AppLogger.shared.info(
                            "✅ Chat completed: \(streamBuffer.count) chars",
                            category: .ollama
                        )
                        delegate?.streamingHandler(self, didCompleteWithContent: streamBuffer)
                        break
                    }

                    let chunk = response.message.content
                    if !chunk.isEmpty {
                        await processChunkWithDelays(chunk)
                    }
                }
            } catch {
                AppLogger.shared.error("Streaming failed: \(error)", category: .ollama)
                delegate?.streamingHandler(self, didFailWithError: error)
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    @MainActor
    private func processChunkWithDelays(_ chunk: String) async {
        if chunk.count < 5 {
            streamBuffer += chunk
            delegate?.streamingHandler(self, didUpdateContent: streamBuffer)
            return
        }

        var remainingContent = chunk
        while !remainingContent.isEmpty {
            if Task.isCancelled { break }

            let chunkSize = min(Int.random(in: 1...3), remainingContent.count)
            let startIndex = remainingContent.startIndex
            let endIndex = remainingContent.index(startIndex, offsetBy: chunkSize)
            let miniChunk = String(remainingContent[startIndex..<endIndex])

            streamBuffer += miniChunk
            delegate?.streamingHandler(self, didUpdateContent: streamBuffer)

            try? await Task.sleep(nanoseconds: 5_000_000)

            remainingContent.removeFirst(chunkSize)
        }
    }
}
