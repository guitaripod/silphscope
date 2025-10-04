import UIKit

struct MarkdownRenderer {
    static func render(_ node: MarkdownNode, style: MarkdownStyle) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = style.spacing.blockSpacing

        switch node {
        case .document(let children):
            for child in children {
                let childView = render(child, style: style)
                stack.addArrangedSubview(childView)
            }

        case .heading(let level, let content):
            let label = createLabel(content: content, style: style)
            label.font = fontForHeading(level: level, style: style)
            stack.addArrangedSubview(label)

        case .paragraph(let content):
            let label = createLabel(content: content, style: style)
            stack.addArrangedSubview(label)

        case .codeBlock(let language, let code):
            let codeView = CodeBlockView(code: code, language: language, style: style.codeBlock)
            stack.addArrangedSubview(codeView)

        case .list(let ordered, let items):
            let listStack = UIStackView()
            listStack.axis = .vertical
            listStack.spacing = 4

            for (index, item) in items.enumerated() {
                let itemStack = UIStackView()
                itemStack.axis = .horizontal
                itemStack.alignment = .top
                itemStack.spacing = 8

                let bullet = UILabel()
                bullet.font = style.fonts.body
                bullet.textColor = style.colors.text
                bullet.text = ordered ? "\(index + 1)." : "•"
                bullet.setContentHuggingPriority(.required, for: .horizontal)
                itemStack.addArrangedSubview(bullet)

                let contentStack = UIStackView()
                contentStack.axis = .vertical
                contentStack.spacing = 4

                for itemNode in item {
                    let itemView = render(itemNode, style: style)
                    contentStack.addArrangedSubview(itemView)
                }

                itemStack.addArrangedSubview(contentStack)
                listStack.addArrangedSubview(itemStack)
            }

            stack.addArrangedSubview(listStack)

        case .blockquote(let children):
            let quoteContainer = UIView()
            quoteContainer.translatesAutoresizingMaskIntoConstraints = false

            let borderView = UIView()
            borderView.backgroundColor = style.colors.quote
            borderView.translatesAutoresizingMaskIntoConstraints = false
            quoteContainer.addSubview(borderView)

            let contentStack = UIStackView()
            contentStack.axis = .vertical
            contentStack.spacing = style.spacing.blockSpacing
            contentStack.translatesAutoresizingMaskIntoConstraints = false

            for child in children {
                let childView = render(child, style: style)
                contentStack.addArrangedSubview(childView)
            }

            quoteContainer.addSubview(contentStack)

            NSLayoutConstraint.activate([
                borderView.leadingAnchor.constraint(equalTo: quoteContainer.leadingAnchor),
                borderView.topAnchor.constraint(equalTo: quoteContainer.topAnchor),
                borderView.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor),
                borderView.widthAnchor.constraint(equalToConstant: 4),

                contentStack.leadingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: 12),
                contentStack.trailingAnchor.constraint(equalTo: quoteContainer.trailingAnchor),
                contentStack.topAnchor.constraint(equalTo: quoteContainer.topAnchor),
                contentStack.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor)
            ])

            stack.addArrangedSubview(quoteContainer)

        case .table(let header, let rows, let alignment):
            let tableView = TableView(
                header: header,
                rows: rows,
                alignment: alignment,
                style: style.table,
                markdownStyle: style
            )
            stack.addArrangedSubview(tableView)

        case .horizontalRule:
            let separator = UIView()
            separator.backgroundColor = style.colors.tableBorder
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            stack.addArrangedSubview(separator)
        }

        return stack
    }

    private static func createLabel(content: [InlineNode], style: MarkdownStyle) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = TextRenderer.render(content, style: style)
        return label
    }

    private static func fontForHeading(level: Int, style: MarkdownStyle) -> UIFont {
        switch level {
        case 1: return style.fonts.h1
        case 2: return style.fonts.h2
        case 3: return style.fonts.h3
        case 4: return style.fonts.h4
        case 5: return style.fonts.h5
        case 6: return style.fonts.h6
        default: return style.fonts.body
        }
    }
}
