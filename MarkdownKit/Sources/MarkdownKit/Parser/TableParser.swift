import Foundation

struct TableParser {
    static func parse(lines: [String]) -> MarkdownNode? {
        guard lines.count >= 2 else { return nil }

        let headerLine = lines[0].trimmingCharacters(in: .whitespaces)
        let separatorLine = lines[1].trimmingCharacters(in: .whitespaces)

        guard isSeparatorLine(separatorLine) else { return nil }

        let header = parseCells(headerLine)
        let alignment = parseAlignment(separatorLine, columnCount: header.count)
        let bodyLines = Array(lines.dropFirst(2))
        let rows = bodyLines.map { parseCells($0) }

        return .table(header: header, rows: rows, alignment: alignment)
    }

    static func isSeparatorLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") || trimmed.contains("|") else { return false }

        let pattern = "^\\s*\\|?\\s*:?-+:?\\s*(\\|\\s*:?-+:?\\s*)+\\|?\\s*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return regex?.firstMatch(in: trimmed, range: range) != nil
    }

    static func parseCells(_ line: String) -> [TableCell] {
        var cells: [String] = []
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        let withoutOuterPipes = trimmed.hasPrefix("|") && trimmed.hasSuffix("|")
            ? String(trimmed.dropFirst().dropLast())
            : trimmed

        var currentCell = ""
        var inBackticks = false

        for char in withoutOuterPipes {
            if char == "`" {
                inBackticks.toggle()
                currentCell.append(char)
            } else if char == "|" && !inBackticks {
                cells.append(currentCell.trimmingCharacters(in: .whitespaces))
                currentCell = ""
            } else {
                currentCell.append(char)
            }
        }

        if !currentCell.isEmpty || withoutOuterPipes.hasSuffix("|") {
            cells.append(currentCell.trimmingCharacters(in: .whitespaces))
        }

        return cells.map { TableCell(content: InlineParser.parse($0)) }
    }

    static func parseAlignment(_ line: String, columnCount: Int) -> [TableAlignment] {
        let cells = line
            .trimmingCharacters(in: .whitespaces)
            .split(separator: "|", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let alignments = cells.map { cell -> TableAlignment in
            let startsWithColon = cell.hasPrefix(":")
            let endsWithColon = cell.hasSuffix(":")

            if startsWithColon && endsWithColon {
                return .center
            } else if endsWithColon {
                return .right
            } else if startsWithColon {
                return .left
            } else {
                return .none
            }
        }

        while alignments.count < columnCount {
            return alignments + Array(repeating: .none, count: columnCount - alignments.count)
        }

        return Array(alignments.prefix(columnCount))
    }
}
