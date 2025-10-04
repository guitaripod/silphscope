import Foundation

struct InlineParser {
    static func parse(_ text: String) -> [InlineNode] {
        guard !text.isEmpty else { return [] }

        var nodes: [InlineNode] = []
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            if let (node, nextIndex) = parseNext(from: text, startingAt: currentIndex) {
                nodes.append(node)
                currentIndex = nextIndex
            } else {
                currentIndex = text.index(after: currentIndex)
            }
        }

        return mergeConsecutiveText(nodes)
    }

    private static func parseNext(from text: String, startingAt index: String.Index) -> (InlineNode, String.Index)? {
        if let result = tryParseCode(from: text, startingAt: index) {
            return result
        }

        if let result = tryParseStrong(from: text, startingAt: index) {
            return result
        }

        if let result = tryParseEmphasis(from: text, startingAt: index) {
            return result
        }

        if let result = tryParseLink(from: text, startingAt: index) {
            return result
        }

        if index < text.endIndex {
            let nextIndex = text.index(after: index)
            return (.text(String(text[index])), nextIndex)
        }

        return nil
    }

    private static func tryParseCode(from text: String, startingAt index: String.Index) -> (InlineNode, String.Index)? {
        guard index < text.endIndex, text[index] == "`" else { return nil }

        let afterBacktick = text.index(after: index)
        guard let closingIndex = text[afterBacktick...].firstIndex(of: "`") else {
            return nil
        }

        let code = String(text[afterBacktick..<closingIndex])
        let nextIndex = text.index(after: closingIndex)
        return (.code(code), nextIndex)
    }

    private static func tryParseStrong(from text: String, startingAt index: String.Index) -> (InlineNode, String.Index)? {
        if let result = tryParseDelimited(from: text, startingAt: index, delimiter: "**") {
            return (.strong(result.content), result.nextIndex)
        }

        if let result = tryParseDelimited(from: text, startingAt: index, delimiter: "__") {
            return (.strong(result.content), result.nextIndex)
        }

        return nil
    }

    private static func tryParseEmphasis(from text: String, startingAt index: String.Index) -> (InlineNode, String.Index)? {
        if let result = tryParseDelimited(from: text, startingAt: index, delimiter: "*") {
            return (.emphasis(result.content), result.nextIndex)
        }

        if let result = tryParseDelimited(from: text, startingAt: index, delimiter: "_") {
            return (.emphasis(result.content), result.nextIndex)
        }

        return nil
    }

    private static func tryParseLink(from text: String, startingAt index: String.Index) -> (InlineNode, String.Index)? {
        guard index < text.endIndex, text[index] == "[" else { return nil }

        let afterBracket = text.index(after: index)
        guard let closingBracket = text[afterBracket...].firstIndex(of: "]") else {
            return nil
        }

        let afterClosingBracket = text.index(after: closingBracket)
        guard afterClosingBracket < text.endIndex, text[afterClosingBracket] == "(" else {
            return nil
        }

        let afterParen = text.index(after: afterClosingBracket)
        guard let closingParen = text[afterParen...].firstIndex(of: ")") else {
            return nil
        }

        let linkText = String(text[afterBracket..<closingBracket])
        let url = String(text[afterParen..<closingParen])
        let content = parse(linkText)
        let nextIndex = text.index(after: closingParen)

        return (.link(text: content, url: url), nextIndex)
    }

    private static func tryParseDelimited(
        from text: String,
        startingAt index: String.Index,
        delimiter: String
    ) -> (content: [InlineNode], nextIndex: String.Index)? {
        guard text[index...].hasPrefix(delimiter) else { return nil }

        let delimiterLength = delimiter.count
        let startContent = text.index(index, offsetBy: delimiterLength)

        guard let closingRange = findClosingDelimiter(in: text, delimiter: delimiter, after: startContent) else {
            return nil
        }

        let content = String(text[startContent..<closingRange.lowerBound])
        let parsed = parse(content)
        let nextIndex = closingRange.upperBound

        return (parsed, nextIndex)
    }

    private static func findClosingDelimiter(
        in text: String,
        delimiter: String,
        after startIndex: String.Index
    ) -> Range<String.Index>? {
        var searchIndex = startIndex

        while searchIndex < text.endIndex {
            if text[searchIndex...].hasPrefix(delimiter) {
                let endIndex = text.index(searchIndex, offsetBy: delimiter.count)
                return searchIndex..<endIndex
            }
            searchIndex = text.index(after: searchIndex)
        }

        return nil
    }

    private static func mergeConsecutiveText(_ nodes: [InlineNode]) -> [InlineNode] {
        var result: [InlineNode] = []

        for node in nodes {
            if case .text(let newText) = node,
               case .text(let existingText)? = result.last {
                result[result.count - 1] = .text(existingText + newText)
            } else {
                result.append(node)
            }
        }

        return result
    }
}
