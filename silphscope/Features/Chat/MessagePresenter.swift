import Foundation
import Swollama

protocol MessagePresenting {
    func formatMessageContent(_ message: ChatViewModel.Message) -> String
    func shouldShowAsThinking(_ message: ChatViewModel.Message) -> Bool
}

final class MessagePresenter: MessagePresenting {

    func formatMessageContent(_ message: ChatViewModel.Message) -> String {
        if message.content.isEmpty && message.isStreaming {
            return "Thinking..."
        } else if message.content.isEmpty {
            return " "
        } else {
            return message.content
        }
    }

    func shouldShowAsThinking(_ message: ChatViewModel.Message) -> Bool {
        return message.content.isEmpty && message.isStreaming
    }
}
