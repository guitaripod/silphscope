import Foundation
import StreamingTextKit

extension ChatViewModel.Message {
    var asStreamingTextMessage: StreamingTextMessage {
        StreamingTextMessage(
            id: id,
            source: role == .user ? .local : .remote,
            content: content,
            timestamp: timestamp,
            isStreaming: isStreaming
        )
    }
}
