import UIKit

public final class MarkdownView: UIView {
    private var contentView: UIView?

    public var markdown: String? {
        didSet {
            render()
        }
    }

    public var style: MarkdownStyle = .default {
        didSet {
            render()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func render() {
        contentView?.removeFromSuperview()

        guard let markdown = markdown, !markdown.isEmpty else {
            return
        }

        let ast = MarkdownParser.parse(markdown)
        let rendered = MarkdownRenderer.render(ast, style: style)

        rendered.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rendered)

        NSLayoutConstraint.activate([
            rendered.topAnchor.constraint(equalTo: topAnchor),
            rendered.leadingAnchor.constraint(equalTo: leadingAnchor),
            rendered.trailingAnchor.constraint(equalTo: trailingAnchor),
            rendered.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        contentView = rendered
    }
}
