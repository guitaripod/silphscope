import Foundation

public enum MarkdownNode: Equatable {
    case document([MarkdownNode])
    case heading(level: Int, content: [InlineNode])
    case paragraph([InlineNode])
    case codeBlock(language: String?, code: String)
    case list(ordered: Bool, items: [[MarkdownNode]])
    case blockquote([MarkdownNode])
    case table(header: [TableCell], rows: [[TableCell]], alignment: [TableAlignment])
    case horizontalRule
}

public struct TableCell: Equatable {
    public let content: [InlineNode]

    public init(content: [InlineNode]) {
        self.content = content
    }
}

public enum TableAlignment: Equatable {
    case left
    case center
    case right
    case none
}

public indirect enum InlineNode: Equatable {
    case text(String)
    case strong([InlineNode])
    case emphasis([InlineNode])
    case code(String)
    case link(text: [InlineNode], url: String)
}
