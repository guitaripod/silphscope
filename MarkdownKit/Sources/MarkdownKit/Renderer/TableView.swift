import UIKit

public final class TableView: UIView {
    private let containerStack = UIStackView()

    public var header: [TableCell] {
        didSet { rebuildTable() }
    }

    public var rows: [[TableCell]] {
        didSet { rebuildTable() }
    }

    public var alignment: [TableAlignment] {
        didSet { rebuildTable() }
    }

    public var style: TableStyle {
        didSet { updateStyle() }
    }

    private var markdownStyle: MarkdownStyle

    public init(
        header: [TableCell],
        rows: [[TableCell]],
        alignment: [TableAlignment],
        style: TableStyle,
        markdownStyle: MarkdownStyle
    ) {
        self.header = header
        self.rows = rows
        self.alignment = alignment
        self.style = style
        self.markdownStyle = markdownStyle
        super.init(frame: .zero)
        setupViews()
        updateStyle()
        rebuildTable()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        containerStack.axis = .vertical
        containerStack.spacing = 0
        addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateStyle() {
        backgroundColor = .clear
        layer.cornerRadius = style.cornerRadius
        layer.borderWidth = style.borderWidth
        layer.borderColor = style.borderColor.cgColor
        clipsToBounds = true
    }

    private func rebuildTable() {
        containerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let columnCount = header.count
        let columnWidths = calculateColumnWidths(columnCount: columnCount)

        let headerRow = createRow(
            cells: header,
            alignment: alignment,
            columnWidths: columnWidths,
            isHeader: true,
            rowIndex: 0
        )
        containerStack.addArrangedSubview(headerRow)

        for (index, row) in rows.enumerated() {
            let rowView = createRow(
                cells: row,
                alignment: alignment,
                columnWidths: columnWidths,
                isHeader: false,
                rowIndex: index + 1
            )
            containerStack.addArrangedSubview(rowView)
        }
    }

    private func createRow(
        cells: [TableCell],
        alignment: [TableAlignment],
        columnWidths: [CGFloat],
        isHeader: Bool,
        rowIndex: Int
    ) -> UIView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 0
        rowStack.distribution = .fillEqually

        if isHeader {
            rowStack.backgroundColor = style.headerBackground
        } else if let altColor = style.alternateRowBackground, rowIndex % 2 == 0 {
            rowStack.backgroundColor = altColor
        } else {
            rowStack.backgroundColor = .clear
        }

        for (index, cell) in cells.enumerated() {
            let cellAlignment = index < alignment.count ? alignment[index] : .none
            let cellWidth = index < columnWidths.count ? columnWidths[index] : 100

            let cellView = createCell(
                cell: cell,
                alignment: cellAlignment,
                isHeader: isHeader,
                width: cellWidth
            )

            rowStack.addArrangedSubview(cellView)

            if index < cells.count - 1 {
                let separator = UIView()
                separator.backgroundColor = style.borderColor
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.widthAnchor.constraint(equalToConstant: style.borderWidth).isActive = true
                rowStack.addArrangedSubview(separator)
            }
        }

        return rowStack
    }

    private func createCell(
        cell: TableCell,
        alignment: TableAlignment,
        isHeader: Bool,
        width: CGFloat
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false

        let font = isHeader ? style.headerFont : style.bodyFont
        var tempStyle = markdownStyle
        tempStyle.fonts.body = font

        let attributed = TextRenderer.render(cell.content, style: tempStyle)
        label.attributedText = attributed

        switch alignment {
        case .left, .none:
            label.textAlignment = .left
        case .center:
            label.textAlignment = .center
        case .right:
            label.textAlignment = .right
        }

        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: style.cellPadding.top),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: style.cellPadding.left),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -style.cellPadding.right),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -style.cellPadding.bottom)
        ])

        return container
    }

    private func calculateColumnWidths(columnCount: Int) -> [CGFloat] {
        let minWidth: CGFloat = 80
        return Array(repeating: minWidth, count: columnCount)
    }
}
