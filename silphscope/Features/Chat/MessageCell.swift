import UIKit
final class MessageCell: UITableViewCell {

    static let reuseIdentifier = "MessageCell"

    private let bubbleContainer: UIView = {
        let view = UIView()
        view.setupForAutoLayout()
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.setupForAutoLayout()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    private let streamingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.setupForAutoLayout()
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.setupForAutoLayout()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(streamingIndicator)

        bubbleContainer.addSubview(stackView)
        contentView.addSubview(bubbleContainer)

        let minHeightConstraint = messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        minHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: bubbleContainer.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bubbleContainer.bottomAnchor, constant: -12),

            bubbleContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            minHeightConstraint
        ])

        leadingConstraint = bubbleContainer.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 16
        )
        trailingConstraint = bubbleContainer.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        leadingConstraint.isActive = true
    }

    func configure(with message: ChatViewModel.Message) {
        if message.content.isEmpty && message.isStreaming {
            messageLabel.text = "Generating..."
        } else if message.content.isEmpty {
            messageLabel.text = " "
        } else {
            messageLabel.text = message.content
        }

        let isUser = message.role == .user

        if isUser {
            bubbleContainer.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            leadingConstraint.constant = 80
            trailingConstraint.isActive = true
            streamingIndicator.style = .medium
            streamingIndicator.color = .white
        } else {
            bubbleContainer.backgroundColor = .systemGray5
            messageLabel.textColor = .label
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            streamingIndicator.style = .medium
            streamingIndicator.color = .gray
        }

        if message.isStreaming {
            streamingIndicator.startAnimating()
        } else {
            streamingIndicator.stopAnimating()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        streamingIndicator.stopAnimating()
    }
}
