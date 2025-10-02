import UIKit
final class ChatInputBar: UIView {

    var onSendMessage: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var isGenerating = false {
        didSet {
            updateSendButton()
        }
    }

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.setupForAutoLayout()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .bottom
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return stack
    }()

    private let textViewContainer: UIView = {
        let view = UIView()
        view.setupForAutoLayout()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        return view
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.setupForAutoLayout()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.isScrollEnabled = false
        tv.delegate = self
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.setupForAutoLayout()
        label.text = "Message"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .placeholderText
        return label
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setupForAutoLayout()
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])

        return button
    }()

    private var textViewHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        addSubview(containerStack)
        containerStack.pinToSafeArea(insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))

        textViewContainer.addSubviews(textView, placeholderLabel)

        textViewHeightConstraint = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        textViewHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textViewHeightConstraint,
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 8)
        ])

        containerStack.addArrangedSubview(textViewContainer)
        containerStack.addArrangedSubview(sendButton)
        let border = UIView()
        border.setupForAutoLayout()
        border.backgroundColor = .separator
        addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: topAnchor),
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        updateSendButton()
    }

    func setGenerating(_ generating: Bool) {
        isGenerating = generating
    }

    func clearText() {
        textView.text = ""
        updatePlaceholder()
        updateSendButton()
    }

    private func updateSendButton() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isGenerating {
            sendButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
            sendButton.tintColor = .systemRed
            sendButton.isEnabled = true
        } else {
            sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
            sendButton.tintColor = hasText ? .systemBlue : .systemGray3
            sendButton.isEnabled = hasText
        }
    }

    private func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    @objc private func sendButtonTapped() {
        if isGenerating {
            onCancel?()
        } else {
            let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            onSendMessage?(text)
            clearText()
        }
    }
}

extension ChatInputBar: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateSendButton()
    }
}
