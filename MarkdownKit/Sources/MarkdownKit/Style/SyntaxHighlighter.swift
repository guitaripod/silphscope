import UIKit

struct SyntaxHighlighter {
    static func highlight(code: String, language: String?, font: UIFont, textColor: UIColor) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: code,
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )

        guard let lang = language?.lowercased() else {
            return attributed
        }

        switch lang {
        case "swift":
            highlightSwift(attributed)
        case "python", "py":
            highlightPython(attributed)
        case "javascript", "js", "typescript", "ts":
            highlightJavaScript(attributed)
        case "json":
            highlightJSON(attributed)
        case "bash", "sh", "shell":
            highlightShell(attributed)
        default:
            break
        }

        return attributed
    }

    private static func highlightSwift(_ text: NSMutableAttributedString) {
        let keywords = [
            "func", "var", "let", "class", "struct", "enum", "protocol", "extension",
            "import", "return", "if", "else", "guard", "switch", "case", "default",
            "for", "while", "in", "break", "continue", "nil", "true", "false",
            "public", "private", "internal", "fileprivate", "static", "final",
            "override", "mutating", "init", "deinit", "self", "Self", "super",
            "throws", "throw", "try", "catch", "async", "await", "actor"
        ]

        applyColors(to: text, keywords: keywords, keywordColor: .systemPurple)
        highlightStrings(text, color: .systemRed)
        highlightComments(text, singleLine: "//", multiLine: ("/*", "*/"), color: .systemGreen)
    }

    private static func highlightPython(_ text: NSMutableAttributedString) {
        let keywords = [
            "def", "class", "if", "else", "elif", "for", "while", "in", "return",
            "import", "from", "as", "try", "except", "finally", "with", "lambda",
            "pass", "break", "continue", "None", "True", "False", "and", "or", "not",
            "async", "await", "yield"
        ]

        applyColors(to: text, keywords: keywords, keywordColor: .systemPurple)
        highlightStrings(text, color: .systemRed)
        highlightComments(text, singleLine: "#", multiLine: nil, color: .systemGreen)
    }

    private static func highlightJavaScript(_ text: NSMutableAttributedString) {
        let keywords = [
            "function", "const", "let", "var", "class", "if", "else", "for", "while",
            "return", "import", "export", "from", "default", "new", "this", "super",
            "try", "catch", "finally", "throw", "async", "await", "typeof", "instanceof",
            "null", "undefined", "true", "false"
        ]

        applyColors(to: text, keywords: keywords, keywordColor: .systemPurple)
        highlightStrings(text, color: .systemRed)
        highlightComments(text, singleLine: "//", multiLine: ("/*", "*/"), color: .systemGreen)
    }

    private static func highlightJSON(_ text: NSMutableAttributedString) {
        highlightStrings(text, color: .systemRed)

        let numberPattern = ":\\s*(-?\\d+\\.?\\d*)"
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let range = NSRange(location: 0, length: text.length)
            regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
                if let matchRange = match?.range(at: 1) {
                    text.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: matchRange)
                }
            }
        }

        let boolPattern = ":\\s*(true|false|null)"
        if let regex = try? NSRegularExpression(pattern: boolPattern) {
            let range = NSRange(location: 0, length: text.length)
            regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
                if let matchRange = match?.range(at: 1) {
                    text.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: matchRange)
                }
            }
        }
    }

    private static func highlightShell(_ text: NSMutableAttributedString) {
        let keywords = [
            "if", "then", "else", "elif", "fi", "case", "esac", "for", "while",
            "do", "done", "function", "return", "exit", "echo", "cd", "ls", "mkdir",
            "rm", "cp", "mv", "grep", "sed", "awk"
        ]

        applyColors(to: text, keywords: keywords, keywordColor: .systemPurple)
        highlightStrings(text, color: .systemRed)
        highlightComments(text, singleLine: "#", multiLine: nil, color: .systemGreen)
    }

    private static func applyColors(
        to text: NSMutableAttributedString,
        keywords: [String],
        keywordColor: UIColor
    ) {
        let pattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let range = NSRange(location: 0, length: text.length)
        regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
            if let matchRange = match?.range {
                text.addAttribute(.foregroundColor, value: keywordColor, range: matchRange)
            }
        }
    }

    private static func highlightStrings(_ text: NSMutableAttributedString, color: UIColor) {
        let patterns = [
            "\"(?:[^\"\\\\]|\\\\.)*\"",
            "'(?:[^'\\\\]|\\\\.)*'"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(location: 0, length: text.length)

            regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
                if let matchRange = match?.range {
                    text.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        }
    }

    private static func highlightComments(
        _ text: NSMutableAttributedString,
        singleLine: String?,
        multiLine: (String, String)?,
        color: UIColor
    ) {
        if let single = singleLine {
            let pattern = "\(NSRegularExpression.escapedPattern(for: single)).*$"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { return }
            let range = NSRange(location: 0, length: text.length)

            regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
                if let matchRange = match?.range {
                    text.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        }

        if let (start, end) = multiLine {
            let pattern = "\(NSRegularExpression.escapedPattern(for: start)).*?\(NSRegularExpression.escapedPattern(for: end))"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return }
            let range = NSRange(location: 0, length: text.length)

            regex.enumerateMatches(in: text.string, range: range) { match, _, _ in
                if let matchRange = match?.range {
                    text.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        }
    }
}
