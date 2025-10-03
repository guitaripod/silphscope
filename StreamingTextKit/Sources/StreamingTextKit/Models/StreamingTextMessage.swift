import Foundation

public struct StreamingTextMessage: Hashable, Identifiable {
    public enum Source: Hashable {
        case local
        case remote
        case system
    }

    public let id: UUID
    public let source: Source
    public var content: String
    public let timestamp: Date
    public var isStreaming: Bool

    public init(
        id: UUID = UUID(),
        source: Source,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.source = source
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(content)
    }

    public static func == (lhs: StreamingTextMessage, rhs: StreamingTextMessage) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content
    }
}
