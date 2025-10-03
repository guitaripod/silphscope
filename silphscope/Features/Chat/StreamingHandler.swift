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
    private var chunkBuffer: [String] = []
    private var currentTask: Task<Void, Never>?

    func startStreaming(
        _ stream: AsyncThrowingStream<ChatResponse, Error>
    ) {
        streamBuffer = ""
        chunkBuffer = []

        currentTask = Task {
            do {
                var isFirstUpdate = true

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
                        if !chunkBuffer.isEmpty {
                            flushChunkBuffer()
                        }
                        delegate?.streamingHandler(self, didCompleteWithContent: streamBuffer)
                        break
                    }

                    let chunk = response.message.content
                    if !chunk.isEmpty {
                        if isFirstUpdate {
                            streamBuffer = chunk
                            delegate?.streamingHandler(self, didUpdateContent: streamBuffer)
                            isFirstUpdate = false
                        } else {
                            chunkBuffer.append(chunk)

                            let bufferedText = chunkBuffer.joined()
                            let shouldUpdate =
                                chunkBuffer.count >= 4 || bufferedText.contains("\n")
                                || bufferedText.count > 40

                            if shouldUpdate {
                                flushChunkBuffer()
                            }
                        }
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
        if !chunkBuffer.isEmpty {
            flushChunkBuffer()
        }
    }

    private func flushChunkBuffer() {
        guard !chunkBuffer.isEmpty else { return }

        let newContent = chunkBuffer.joined()
        streamBuffer += newContent
        chunkBuffer.removeAll()

        delegate?.streamingHandler(self, didUpdateContent: streamBuffer)
    }
}
