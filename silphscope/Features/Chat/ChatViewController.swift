import StreamingTextKit
import Swollama
import UIKit

final class ChatViewController: UIViewController {

    private let viewModel = ChatViewModel()
    private var dataSource: UICollectionViewDiffableDataSource<Int, ChatViewModel.Message>!
    private var observationTask: Task<Void, Never>?

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.setupForAutoLayout()
        cv.backgroundColor = .systemBackground
        cv.keyboardDismissMode = .interactive
        cv.contentInsetAdjustmentBehavior = .automatic
        cv.alwaysBounceVertical = true
        cv.register(
            StreamingMessageCell.self,
            forCellWithReuseIdentifier: StreamingMessageCell.identifier
        )
        return cv
    }()

    private lazy var inputContainer: UIView = {
        let view = UIView()
        view.setupForAutoLayout()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -1)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        return view
    }()

    private lazy var inputStackView: UIStackView = {
        let stack = UIStackView()
        stack.setupForAutoLayout()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .bottom
        stack.distribution = .fill
        return stack
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.setupForAutoLayout()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 20
        tv.layer.cornerCurve = .continuous
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        tv.isScrollEnabled = false
        tv.returnKeyType = .send
        tv.delegate = self
        tv.inputAccessoryView = nil
        return tv
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setupForAutoLayout()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        btn.setImage(
            UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config),
            for: .normal
        )
        btn.tintColor = .systemBlue
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setupForAutoLayout()
        btn.setTitle("Cancel", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return btn
    }()

    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var textViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupDataSource()
        observeViewModel()
        setupNavigationBar()
        setupKeyboardObservers()

        #if DEBUG
            textView.text = "Explain love in detail."
            updateTextViewHeight()
            updateSendButtonState()
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    deinit {
        observationTask?.cancel()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputStackView)
        inputStackView.addArrangedSubview(textView)
        inputStackView.addArrangedSubview(sendButton)
        inputStackView.addArrangedSubview(cancelButton)
        cancelButton.isHidden = true
    }

    private func setupConstraints() {
        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 40)
        inputContainerBottomConstraint = inputContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,

            inputStackView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            inputStackView.leadingAnchor.constraint(
                equalTo: inputContainer.leadingAnchor,
                constant: 16
            ),
            inputStackView.trailingAnchor.constraint(
                equalTo: inputContainer.trailingAnchor,
                constant: -16
            ),
            inputStackView.bottomAnchor.constraint(
                equalTo: inputContainer.bottomAnchor,
                constant: -8
            ),

            textViewHeightConstraint,
            textView.widthAnchor.constraint(equalTo: inputStackView.widthAnchor, constant: -48),

            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            cancelButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, ChatViewModel.Message>(
            collectionView: collectionView
        ) { collectionView, indexPath, message in
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: StreamingMessageCell.identifier,
                    for: indexPath
                ) as! StreamingMessageCell
            cell.configure(with: message)
            return cell
        }
    }

    private func observeViewModel() {
        observeMessages()
        observeGeneratingState()
        observeErrors()
    }

    private func observeMessages() {
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let messages = withObservationTracking {
                    self.viewModel.messages
                } onChange: {
                    Task { @MainActor [weak self] in
                        self?.observeMessages()
                    }
                }

                updateMessages(messages)
                break
            }
        }
    }

    private func observeGeneratingState() {
        Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let isGenerating = withObservationTracking {
                    self.viewModel.isGenerating
                } onChange: {
                    Task { @MainActor [weak self] in
                        self?.observeGeneratingState()
                    }
                }

                handleGeneratingStateChange(isGenerating)
                break
            }
        }
    }

    private func observeErrors() {
        Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let error = withObservationTracking {
                    self.viewModel.error
                } onChange: {
                    Task { @MainActor [weak self] in
                        self?.observeErrors()
                    }
                }

                if let error {
                    showError(error)
                }
                break
            }
        }
    }

    private func updateMessages(_ messages: [ChatViewModel.Message]) {
        let isStreaming = messages.last?.isStreaming ?? false

        if isStreaming && !messages.isEmpty {
            updateStreamingMessage(messages)
        } else {
            let lastIndexPath = IndexPath(item: messages.count - 1, section: 0)
            if !messages.isEmpty, collectionView.cellForItem(at: lastIndexPath) != nil {
                return
            }
            updateSnapshot(with: messages, animated: true)
        }
    }

    private func updateStreamingMessage(_ messages: [ChatViewModel.Message]) {
        let lastIndexPath = IndexPath(item: messages.count - 1, section: 0)

        if let cell = collectionView.cellForItem(at: lastIndexPath) as? StreamingMessageCell {
            let previousHeight = cell.frame.height
            cell.updateContent(messages.last!)

            let newHeight = cell.contentView.systemLayoutSizeFitting(
                CGSize(width: cell.frame.width, height: UIView.layoutFittingExpandedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height

            if abs(newHeight - previousHeight) > 1 {
                UIView.performWithoutAnimation {
                    collectionView.collectionViewLayout.invalidateLayout()
                }
            }

            let contentHeight = collectionView.contentSize.height
            let frameHeight = collectionView.frame.height

            if contentHeight > frameHeight {
                let bottomOffset = max(
                    0,
                    contentHeight - frameHeight + collectionView.contentInset.bottom
                )
                collectionView.contentOffset = CGPoint(x: 0, y: bottomOffset)
            }
        } else {
            updateSnapshot(with: messages, animated: false)
        }
    }

    private func updateSnapshot(with messages: [ChatViewModel.Message], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatViewModel.Message>()
        snapshot.appendSections([0])
        snapshot.appendItems(messages)

        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self, !messages.isEmpty else { return }

            let lastIndexPath = IndexPath(item: messages.count - 1, section: 0)
            self.collectionView.scrollToItem(
                at: lastIndexPath,
                at: .bottom,
                animated: animated
            )
        }
    }

    private func maintainBottomScroll() {
        let contentHeight = collectionView.contentSize.height
        let frameHeight = collectionView.frame.height

        guard contentHeight > frameHeight else { return }

        let bottomOffset = max(0, contentHeight - frameHeight)

        UIView.performWithoutAnimation {
            self.collectionView.contentOffset = CGPoint(x: 0, y: bottomOffset)
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupNavigationBar() {
        title = "Chat"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearChat)
        )
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func sendTapped() {
        let text = textView.text ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        textView.text = ""
        updateTextViewHeight()
        updateSendButtonState()

        Task {
            await viewModel.sendMessage(text)
        }
    }

    @objc private func cancelTapped() {
        viewModel.cancelGeneration()
    }

    @objc private func clearChat() {
        let alert = UIAlertController(
            title: "Clear Chat",
            message: "Clear all messages?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
                self?.viewModel.clearMessages()
            }
        )

        present(alert, animated: true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double,
            let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]
                as? Int,
            let curve = UIView.AnimationCurve(rawValue: curveValue)
        else { return }

        let keyboardHeight =
            keyboardFrame.origin.y >= UIScreen.main.bounds.height ? 0 : keyboardFrame.height

        inputContainerBottomConstraint.constant = -keyboardHeight

        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.view.layoutIfNeeded()
        }

        animator.startAnimation()
    }

    private func updateTextViewHeight() {
        let maxHeight: CGFloat = 120
        let contentHeight = textView.sizeThatFits(
            CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        ).height
        textViewHeightConstraint.constant = min(contentHeight, maxHeight)
        textView.isScrollEnabled = contentHeight > maxHeight
    }

    private func updateSendButtonState() {
        let hasText =
            !(textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = hasText

        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = hasText ? 1.0 : 0.5
            self.sendButton.transform = hasText ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func handleGeneratingStateChange(_ isGenerating: Bool) {
        sendButton.isHidden = isGenerating
        cancelButton.isHidden = !isGenerating
        textView.isEditable = !isGenerating
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
        updateSendButtonState()
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if text == "\n" && textView.returnKeyType == .send {
            sendTapped()
            return false
        }
        return true
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

final class StreamingMessageCell: UICollectionViewCell {

    static let identifier = "StreamingMessageCell"

    private let presenter: MessagePresenting = StreamingTextKit.MessagePresenter()

    private let bubbleView: UIView = {
        let view = UIView()
        view.setupForAutoLayout()
        return view
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.setupForAutoLayout()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var bubbleFullWidthLeadingConstraint: NSLayoutConstraint!
    private var bubbleFullWidthTrailingConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(textLabel)

        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(
            greaterThanOrEqualTo: contentView.leadingAnchor,
            constant: 40
        )
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        bubbleFullWidthLeadingConstraint = bubbleView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 8
        )
        bubbleFullWidthTrailingConstraint = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -8
        )

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
    }

    func configure(with message: ChatViewModel.Message) {
        let streamingMessage = message.asStreamingTextMessage
        let isUser = message.role == .user

        NSLayoutConstraint.deactivate([
            bubbleLeadingConstraint,
            bubbleTrailingConstraint,
            bubbleFullWidthLeadingConstraint,
            bubbleFullWidthTrailingConstraint,
        ])

        if isUser {
            bubbleView.backgroundColor = .systemBlue
            bubbleView.layer.cornerRadius = 18
            bubbleView.layer.cornerCurve = .continuous
            textLabel.textColor = .white
            NSLayoutConstraint.activate([bubbleLeadingConstraint, bubbleTrailingConstraint])
        } else {
            bubbleView.backgroundColor = .clear
            bubbleView.layer.cornerRadius = 0
            textLabel.textColor = .label
            NSLayoutConstraint.activate([
                bubbleFullWidthLeadingConstraint, bubbleFullWidthTrailingConstraint,
            ])
        }

        textLabel.text = presenter.formatMessageContent(streamingMessage)
        textLabel.alpha = presenter.shouldShowAsThinking(streamingMessage) ? 0.6 : 1.0
    }

    func updateContent(_ message: ChatViewModel.Message) {
        let streamingMessage = message.asStreamingTextMessage
        let newText = presenter.formatMessageContent(streamingMessage)
        if textLabel.text != newText {
            textLabel.text = newText
            textLabel.alpha = presenter.shouldShowAsThinking(streamingMessage) ? 0.6 : 1.0
            contentView.setNeedsLayout()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel.text = nil
        textLabel.alpha = 1.0
        NSLayoutConstraint.deactivate([
            bubbleLeadingConstraint,
            bubbleTrailingConstraint,
            bubbleFullWidthLeadingConstraint,
            bubbleFullWidthTrailingConstraint,
        ])
    }
}
