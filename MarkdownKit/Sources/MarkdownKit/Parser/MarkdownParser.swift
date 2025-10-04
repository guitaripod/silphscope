import Foundation

public struct MarkdownParser {
    public static func parse(_ markdown: String) -> MarkdownNode {
        let lines = markdown.components(separatedBy: .newlines)
        let nodes = parseLines(lines)
        return .document(nodes)
    }

    private static func parseLines(_ lines: [String]) -> [MarkdownNode] {
        var nodes: [MarkdownNode] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

            if let (node, consumed) = tryParseCodeBlock(from: lines, startingAt: index) {
                nodes.append(node)
                index += consumed
                continue
            }

            if let (node, consumed) = tryParseTable(from: lines, startingAt: index) {
                nodes.append(node)
                index += consumed
                continue
            }

            if let (node, consumed) = tryParseList(from: lines, startingAt: index) {
                nodes.append(node)
                index += consumed
                continue
            }

            if let node = tryParseHeading(line) {
                nodes.append(node)
                index += 1
                continue
            }

            if let node = tryParseHorizontalRule(line) {
                nodes.append(node)
                index += 1
                continue
            }

            if let (node, consumed) = tryParseBlockquote(from: lines, startingAt: index) {
                nodes.append(node)
                index += consumed
                continue
            }

            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                if let (node, consumed) = tryParseParagraph(from: lines, startingAt: index) {
                    nodes.append(node)
                    index += consumed
                    continue
                }
            }

            index += 1
        }

        return nodes
    }

    private static func tryParseHeading(_ line: String) -> MarkdownNode? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        var level = 0
        var index = trimmed.startIndex

        while index < trimmed.endIndex && trimmed[index] == "#" && level < 6 {
            level += 1
            index = trimmed.index(after: index)
        }

        guard index < trimmed.endIndex, trimmed[index] == " " else {
            return nil
        }

        let content = String(trimmed[trimmed.index(after: index)...])
        let inlineNodes = InlineParser.parse(content)

        return .heading(level: level, content: inlineNodes)
    }

    private static func tryParseCodeBlock(from lines: [String], startingAt index: Int) -> (MarkdownNode, Int)? {
        guard index < lines.count else { return nil }

        let line = lines[index].trimmingCharacters(in: .whitespaces)
        guard line.hasPrefix("```") else { return nil }

        let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var currentIndex = index + 1

        while currentIndex < lines.count {
            let currentLine = lines[currentIndex]
            if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                let code = codeLines.joined(separator: "\n")
                let lang = language.isEmpty ? nil : language
                return (.codeBlock(language: lang, code: code), currentIndex - index + 1)
            }
            codeLines.append(currentLine)
            currentIndex += 1
        }

        return nil
    }

    private static func tryParseTable(from lines: [String], startingAt index: Int) -> (MarkdownNode, Int)? {
        guard index + 1 < lines.count else { return nil }

        var endIndex = index + 2
        while endIndex < lines.count {
            let line = lines[endIndex].trimmingCharacters(in: .whitespaces)
            if line.isEmpty || !line.contains("|") {
                break
            }
            endIndex += 1
        }

        let tableLines = Array(lines[index..<endIndex])
        guard let table = TableParser.parse(lines: tableLines) else {
            return nil
        }

        return (table, endIndex - index)
    }

    private static func tryParseList(from lines: [String], startingAt index: Int) -> (MarkdownNode, Int)? {
        guard index < lines.count else { return nil }

        let firstLine = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let listType = detectListType(firstLine) else { return nil }

        var items: [[MarkdownNode]] = []
        var currentIndex = index

        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespacesAndNewlines)

            if line.isEmpty {
                let nextIndex = currentIndex + 1
                if nextIndex < lines.count {
                    let nextLine = lines[nextIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let nextType = detectListType(nextLine), nextType == listType {
                        currentIndex = nextIndex
                        continue
                    }
                }
                break
            }

            guard let detectedType = detectListType(line), detectedType == listType else {
                break
            }

            let content = extractListItemContent(line, isOrdered: listType == .ordered)
            let inlineNodes = InlineParser.parse(content)
            items.append([.paragraph(inlineNodes)])
            currentIndex += 1
        }

        guard !items.isEmpty else { return nil }

        return (.list(ordered: listType == .ordered, items: items), currentIndex - index)
    }

    private static func tryParseBlockquote(from lines: [String], startingAt index: Int) -> (MarkdownNode, Int)? {
        guard index < lines.count else { return nil }

        let firstLine = lines[index].trimmingCharacters(in: .whitespaces)
        guard firstLine.hasPrefix(">") else { return nil }

        var quoteLines: [String] = []
        var currentIndex = index

        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                break
            }

            if line.hasPrefix(">") {
                let content = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                quoteLines.append(content)
            } else {
                break
            }

            currentIndex += 1
        }

        let content = quoteLines.joined(separator: "\n")
        let nodes = parseLines(content.components(separatedBy: .newlines))

        return (.blockquote(nodes), currentIndex - index)
    }

    private static func tryParseParagraph(from lines: [String], startingAt index: Int) -> (MarkdownNode, Int)? {
        guard index < lines.count else { return nil }

        var paragraphLines: [String] = []
        var currentIndex = index

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                break
            }

            if trimmed.hasPrefix("#") || trimmed.hasPrefix("```") ||
               trimmed.hasPrefix(">") || detectListType(trimmed) != nil ||
               TableParser.isSeparatorLine(trimmed) || isHorizontalRule(trimmed) {
                break
            }

            paragraphLines.append(trimmed)
            currentIndex += 1
        }

        guard !paragraphLines.isEmpty else { return nil }

        let content = paragraphLines.joined(separator: " ")
        let inlineNodes = InlineParser.parse(content)

        return (.paragraph(inlineNodes), currentIndex - index)
    }

    private static func tryParseHorizontalRule(_ line: String) -> MarkdownNode? {
        guard isHorizontalRule(line.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return .horizontalRule
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let patterns = ["---", "***", "___"]

        for pattern in patterns {
            if trimmed.hasPrefix(pattern) && trimmed.allSatisfy({ $0 == pattern.first || $0.isWhitespace }) {
                let count = trimmed.filter { $0 == pattern.first }.count
                if count >= 3 {
                    return true
                }
            }
        }

        return false
    }

    private enum ListType {
        case ordered
        case unordered
    }

    private static func detectListType(_ line: String) -> ListType? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            return .unordered
        }

        let pattern = "^\\d+\\.\\s"
        if let regex = try? NSRegularExpression(pattern: pattern),
           regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
            return .ordered
        }

        return nil
    }

    private static func extractListItemContent(_ line: String, isOrdered: Bool) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if !isOrdered {
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                return String(trimmed.dropFirst(2))
            }
        } else {
            if let dotIndex = trimmed.firstIndex(of: ".") {
                let afterDot = trimmed.index(after: dotIndex)
                if afterDot < trimmed.endIndex {
                    return String(trimmed[afterDot...]).trimmingCharacters(in: .whitespaces)
                }
            }
        }

        return trimmed
    }
}
