import UIKit

public final class CodeBlockView: UIView {
    private let textView = UITextView()
    private let languageLabel = UILabel()

    public var code: String {
        didSet { updateContent() }
    }

    public var language: String? {
        didSet { updateContent() }
    }

    public var style: CodeBlockStyle {
        didSet { updateStyle() }
    }

    public init(code: String, language: String?, style: CodeBlockStyle) {
        self.code = code
        self.language = language
        self.style = style
        super.init(frame: .zero)
        setupViews()
        updateStyle()
        updateContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false

        languageLabel.font = .systemFont(ofSize: 11, weight: .medium)
        languageLabel.textColor = .secondaryLabel
        addSubview(languageLabel)
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),

            languageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            languageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    private func updateStyle() {
        backgroundColor = style.backgroundColor
        layer.cornerRadius = style.cornerRadius
        layer.borderWidth = style.borderWidth
        layer.borderColor = style.borderColor.cgColor
        clipsToBounds = true

        textView.textContainerInset = style.padding

        if style.showLanguage {
            textView.textContainerInset.top = max(style.padding.top, 24)
        }
    }

    private func updateContent() {
        let highlighted = SyntaxHighlighter.highlight(
            code: code,
            language: language,
            font: style.font,
            textColor: style.textColor
        )
        textView.attributedText = highlighted

        if style.showLanguage, let lang = language, !lang.isEmpty {
            languageLabel.text = lang.uppercased()
            languageLabel.isHidden = false
        } else {
            languageLabel.isHidden = true
        }
    }
}
