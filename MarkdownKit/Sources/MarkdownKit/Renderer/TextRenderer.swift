import UIKit

struct TextRenderer {
    static func render(_ nodes: [InlineNode], style: MarkdownStyle) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for node in nodes {
            let attributed = renderNode(node, style: style)
            result.append(attributed)
        }

        return result
    }

    private static func renderNode(_ node: InlineNode, style: MarkdownStyle) -> NSAttributedString {
        switch node {
        case .text(let text):
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: style.fonts.body,
                    .foregroundColor: style.colors.text
                ]
            )

        case .strong(let children):
            let result = NSMutableAttributedString()
            for child in children {
                let childText = renderNode(child, style: style)
                result.append(childText)
            }
            result.addAttribute(
                .font,
                value: style.fonts.bold,
                range: NSRange(location: 0, length: result.length)
            )
            return result

        case .emphasis(let children):
            let result = NSMutableAttributedString()
            for child in children {
                let childText = renderNode(child, style: style)
                result.append(childText)
            }
            result.addAttribute(
                .font,
                value: style.fonts.italic,
                range: NSRange(location: 0, length: result.length)
            )
            return result

        case .code(let code):
            return NSAttributedString(
                string: code,
                attributes: [
                    .font: style.fonts.code,
                    .foregroundColor: style.colors.codeText,
                    .backgroundColor: style.colors.codeBackground
                ]
            )

        case .link(let text, let url):
            let result = NSMutableAttributedString()
            for child in text {
                let childText = renderNode(child, style: style)
                result.append(childText)
            }
            result.addAttributes(
                [
                    .foregroundColor: style.colors.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: url
                ],
                range: NSRange(location: 0, length: result.length)
            )
            return result
        }
    }
}
