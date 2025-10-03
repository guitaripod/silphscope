import Foundation

public final class StreamingTextHandler {

    public weak var delegate: StreamingTextDelegate?

    private var streamBuffer = ""
    private var currentTask: Task<Void, Never>?
    private let typingSpeed: TypingSpeed

    public init(typingSpeed: TypingSpeed = .natural) {
        self.typingSpeed = typingSpeed
    }

    public func startStreaming(_ stream: AsyncThrowingStream<String, Error>) {
        streamBuffer = ""

        currentTask = Task { @MainActor in
            do {
                for try await chunk in stream {
                    if Task.isCancelled {
                        break
                    }

                    if !chunk.isEmpty {
                        await processChunkWithDelays(chunk)
                    }
                }

                delegate?.streamingHandler(self, didCompleteWithContent: streamBuffer)
            } catch {
                delegate?.streamingHandler(self, didFailWithError: error)
            }
        }
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    @MainActor
    private func processChunkWithDelays(_ chunk: String) async {
        if typingSpeed.delayNanoseconds == 0 || chunk.count < 5 {
            streamBuffer += chunk
            delegate?.streamingHandler(self, didUpdateContent: streamBuffer)
            return
        }

        var remainingContent = chunk
        while !remainingContent.isEmpty {
            if Task.isCancelled { break }

            let chunkSize = min(
                Int.random(in: typingSpeed.chunkSize),
                remainingContent.count
            )
            let startIndex = remainingContent.startIndex
            let endIndex = remainingContent.index(startIndex, offsetBy: chunkSize)
            let miniChunk = String(remainingContent[startIndex..<endIndex])

            streamBuffer += miniChunk
            delegate?.streamingHandler(self, didUpdateContent: streamBuffer)

            try? await Task.sleep(nanoseconds: typingSpeed.delayNanoseconds)

            remainingContent.removeFirst(chunkSize)
        }
    }
}
