import Foundation

public protocol MessagePresenting {
    func formatMessageContent(_ message: StreamingTextMessage) -> String
    func shouldShowAsThinking(_ message: StreamingTextMessage) -> Bool
}

public final class MessagePresenter: MessagePresenting {

    public init() {}

    public func formatMessageContent(_ message: StreamingTextMessage) -> String {
        if message.content.isEmpty && message.isStreaming {
            return "Thinking..."
        } else if message.content.isEmpty {
            return " "
        } else {
            return message.content
        }
    }

    public func shouldShowAsThinking(_ message: StreamingTextMessage) -> Bool {
        return message.content.isEmpty && message.isStreaming
    }
}
