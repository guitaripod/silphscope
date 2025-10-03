import Foundation
import Swollama

struct SwollamaStreamAdapter {
    static func adapt(_ ollamaStream: AsyncThrowingStream<ChatResponse, Error>)
        -> AsyncThrowingStream<String, Error>
    {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in ollamaStream {
                        let chunk = response.message.content
                        if !chunk.isEmpty {
                            continuation.yield(chunk)
                        }

                        if response.done {
                            continuation.finish()
                            break
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
