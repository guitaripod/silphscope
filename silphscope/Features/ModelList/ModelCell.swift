import Swollama
import UIKit

final class ModelCell: UITableViewCell {

    static let reuseIdentifier = "ModelCell"

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.setupForAutoLayout()
        stack.axis = .vertical
        stack.spacing = 4
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return stack
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let detailsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private let parameterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setupForAutoLayout()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
        ])
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        contentView.addSubview(containerStack)
        containerStack.pinToSuperview()

        detailsStack.addArrangedSubview(parameterLabel)
        detailsStack.addArrangedSubview(sizeLabel)
        detailsStack.addArrangedSubview(UIView())
        detailsStack.addArrangedSubview(checkmarkImageView)

        containerStack.addArrangedSubview(nameLabel)
        containerStack.addArrangedSubview(detailsStack)
    }

    func configure(with model: ModelListEntry, isSelected: Bool) {
        nameLabel.text = model.name
        sizeLabel.text = formatSize(model.size)
        parameterLabel.text = model.details.parameterSize
        checkmarkImageView.isHidden = !isSelected
        if isSelected {
            backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerStack.layer.borderWidth = 2
            containerStack.layer.borderColor = UIColor.systemBlue.cgColor
            containerStack.layer.cornerRadius = 12
            nameLabel.textColor = .systemBlue
        } else {
            backgroundColor = .systemBackground
            containerStack.layer.borderWidth = 0
            containerStack.layer.borderColor = nil
            nameLabel.textColor = .label
        }
    }

    private func formatSize(_ bytes: UInt64) -> String {
        let gigabytes = Double(bytes) / 1_073_741_824.0
        return String(format: "%.1f GB", gigabytes)
    }
}
