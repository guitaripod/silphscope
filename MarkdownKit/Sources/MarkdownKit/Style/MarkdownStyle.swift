import UIKit

public struct MarkdownStyle {
    public var fonts: Fonts
    public var colors: Colors
    public var spacing: Spacing
    public var codeBlock: CodeBlockStyle
    public var table: TableStyle

    public init(
        fonts: Fonts = .default,
        colors: Colors = .default,
        spacing: Spacing = .default,
        codeBlock: CodeBlockStyle = .default,
        table: TableStyle = .default
    ) {
        self.fonts = fonts
        self.colors = colors
        self.spacing = spacing
        self.codeBlock = codeBlock
        self.table = table
    }

    public static let `default` = MarkdownStyle()

    public static let chat = MarkdownStyle(
        fonts: .chat,
        colors: .chat,
        spacing: .compact,
        codeBlock: .chat,
        table: .chat
    )

    public struct Fonts {
        public var body: UIFont
        public var code: UIFont
        public var h1: UIFont
        public var h2: UIFont
        public var h3: UIFont
        public var h4: UIFont
        public var h5: UIFont
        public var h6: UIFont
        public var bold: UIFont
        public var italic: UIFont
        public var tableHeader: UIFont
        public var tableBody: UIFont

        public init(
            body: UIFont = .systemFont(ofSize: 16),
            code: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular),
            h1: UIFont = .systemFont(ofSize: 28, weight: .bold),
            h2: UIFont = .systemFont(ofSize: 24, weight: .bold),
            h3: UIFont = .systemFont(ofSize: 20, weight: .bold),
            h4: UIFont = .systemFont(ofSize: 18, weight: .semibold),
            h5: UIFont = .systemFont(ofSize: 16, weight: .semibold),
            h6: UIFont = .systemFont(ofSize: 14, weight: .semibold),
            bold: UIFont = .systemFont(ofSize: 16, weight: .bold),
            italic: UIFont = .italicSystemFont(ofSize: 16),
            tableHeader: UIFont = .systemFont(ofSize: 14, weight: .semibold),
            tableBody: UIFont = .systemFont(ofSize: 14)
        ) {
            self.body = body
            self.code = code
            self.h1 = h1
            self.h2 = h2
            self.h3 = h3
            self.h4 = h4
            self.h5 = h5
            self.h6 = h6
            self.bold = bold
            self.italic = italic
            self.tableHeader = tableHeader
            self.tableBody = tableBody
        }

        public static let `default` = Fonts()

        public static let chat = Fonts(
            body: .systemFont(ofSize: 15),
            code: .monospacedSystemFont(ofSize: 13, weight: .regular),
            h1: .systemFont(ofSize: 22, weight: .bold),
            h2: .systemFont(ofSize: 20, weight: .bold),
            h3: .systemFont(ofSize: 18, weight: .bold),
            h4: .systemFont(ofSize: 16, weight: .semibold),
            h5: .systemFont(ofSize: 15, weight: .semibold),
            h6: .systemFont(ofSize: 14, weight: .semibold),
            bold: .systemFont(ofSize: 15, weight: .bold),
            italic: .italicSystemFont(ofSize: 15),
            tableHeader: .systemFont(ofSize: 13, weight: .semibold),
            tableBody: .systemFont(ofSize: 13)
        )
    }

    public struct Colors {
        public var text: UIColor
        public var codeBackground: UIColor
        public var codeText: UIColor
        public var link: UIColor
        public var quote: UIColor
        public var tableBorder: UIColor
        public var tableHeaderBackground: UIColor
        public var tableAlternateRow: UIColor?

        public init(
            text: UIColor = .label,
            codeBackground: UIColor = .secondarySystemBackground,
            codeText: UIColor = .label,
            link: UIColor = .systemBlue,
            quote: UIColor = .secondaryLabel,
            tableBorder: UIColor = .separator,
            tableHeaderBackground: UIColor = .secondarySystemBackground,
            tableAlternateRow: UIColor? = UIColor.systemGray6.withAlphaComponent(0.3)
        ) {
            self.text = text
            self.codeBackground = codeBackground
            self.codeText = codeText
            self.link = link
            self.quote = quote
            self.tableBorder = tableBorder
            self.tableHeaderBackground = tableHeaderBackground
            self.tableAlternateRow = tableAlternateRow
        }

        public static let `default` = Colors()

        public static let chat = Colors(
            text: .label,
            codeBackground: UIColor.systemGray6,
            codeText: .label,
            link: .systemBlue,
            quote: .secondaryLabel,
            tableBorder: .separator,
            tableHeaderBackground: UIColor.systemGray5,
            tableAlternateRow: UIColor.systemGray6.withAlphaComponent(0.5)
        )
    }

    public struct Spacing {
        public var paragraphSpacing: CGFloat
        public var lineSpacing: CGFloat
        public var blockSpacing: CGFloat

        public init(
            paragraphSpacing: CGFloat = 12,
            lineSpacing: CGFloat = 4,
            blockSpacing: CGFloat = 16
        ) {
            self.paragraphSpacing = paragraphSpacing
            self.lineSpacing = lineSpacing
            self.blockSpacing = blockSpacing
        }

        public static let `default` = Spacing()

        public static let compact = Spacing(
            paragraphSpacing: 8,
            lineSpacing: 2,
            blockSpacing: 12
        )
    }
}

public struct CodeBlockStyle {
    public var font: UIFont
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var cornerRadius: CGFloat
    public var padding: UIEdgeInsets
    public var showLanguage: Bool
    public var borderWidth: CGFloat
    public var borderColor: UIColor

    public init(
        font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular),
        backgroundColor: UIColor = .secondarySystemBackground,
        textColor: UIColor = .label,
        cornerRadius: CGFloat = 8,
        padding: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
        showLanguage: Bool = true,
        borderWidth: CGFloat = 0,
        borderColor: UIColor = .separator
    ) {
        self.font = font
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showLanguage = showLanguage
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }

    public static let `default` = CodeBlockStyle()

    public static let chat = CodeBlockStyle(
        font: .monospacedSystemFont(ofSize: 13, weight: .regular),
        backgroundColor: UIColor.systemGray6,
        textColor: .label,
        cornerRadius: 6,
        padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        showLanguage: true,
        borderWidth: 0,
        borderColor: .separator
    )
}

public struct TableStyle {
    public var headerFont: UIFont
    public var bodyFont: UIFont
    public var headerBackground: UIColor
    public var alternateRowBackground: UIColor?
    public var borderColor: UIColor
    public var borderWidth: CGFloat
    public var cellPadding: UIEdgeInsets
    public var cornerRadius: CGFloat
    public var maxWidth: CGFloat?

    public init(
        headerFont: UIFont = .systemFont(ofSize: 14, weight: .semibold),
        bodyFont: UIFont = .systemFont(ofSize: 14),
        headerBackground: UIColor = .secondarySystemBackground,
        alternateRowBackground: UIColor? = UIColor.systemGray6.withAlphaComponent(0.3),
        borderColor: UIColor = .separator,
        borderWidth: CGFloat = 1,
        cellPadding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
        cornerRadius: CGFloat = 8,
        maxWidth: CGFloat? = nil
    ) {
        self.headerFont = headerFont
        self.bodyFont = bodyFont
        self.headerBackground = headerBackground
        self.alternateRowBackground = alternateRowBackground
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cellPadding = cellPadding
        self.cornerRadius = cornerRadius
        self.maxWidth = maxWidth
    }

    public static let `default` = TableStyle()

    public static let chat = TableStyle(
        headerFont: .systemFont(ofSize: 12, weight: .semibold),
        bodyFont: .systemFont(ofSize: 12),
        headerBackground: UIColor.systemGray5,
        alternateRowBackground: UIColor.systemGray6.withAlphaComponent(0.5),
        borderColor: .separator,
        borderWidth: 0.5,
        cellPadding: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6),
        cornerRadius: 6,
        maxWidth: nil
    )
}
