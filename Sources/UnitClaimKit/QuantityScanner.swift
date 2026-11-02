import Foundation

/// Finds quantities in text: a number, or a range of numbers, followed by a unit. Fenced and inline
/// code is skipped.
struct QuantityScanner {
    let characters: [Character]
    private let code: [Bool]

    init(_ characters: [Character]) {
        self.characters = characters
        code = Self.codeMask(characters)
    }

    static let numberWords: [String: Decimal] = [
        "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "twelve": 12
    ]

    func quantities() -> [ScannedQuantity] {
        var found: [ScannedQuantity] = []
        var index = 0
        while index < characters.count {
            if let quantity = quantity(at: index) {
                found.append(quantity)
                index = quantity.end
            } else {
                index += 1
            }
        }
        return found
    }

    private func quantity(at start: Int) -> ScannedQuantity? {
        guard !code[start], startsToken(at: start) else { return nil }
        return numeric(at: start) ?? worded(at: start)
    }

    /// Not inside a word, a number or a path (`v2`, `1,5`, `24/7`).
    private func startsToken(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let before = characters[index - 1]
        return !(before.isLetter || before.isNumber || ".,/^_".contains(before))
    }

    private func numeric(at start: Int) -> ScannedQuantity? {
        let parser = NumberParser(characters: characters)
        guard let low = parser.number(at: start) else { return nil }
        let high = rangeEnd(after: low.end, parser: parser)
        guard let unit = UnitMatcher(characters: characters).match(after: high?.end ?? low.end) else { return nil }
        let first = make(low.number, start: start, unit: unit, wordsOnly: false)
        let second = high.map { make($0.number, start: start, unit: unit, wordsOnly: false) }
        return ScannedQuantity(low: first, high: second, end: unit.end)
    }

    /// `–10`, `-10`, ` to 10` straight after a number.
    private func rangeEnd(after end: Int, parser: NumberParser) -> NumberParser.Parsed? {
        for joiner in ["–", "-", "—", " – ", " - ", " to "] {
            let marker = Array(joiner)
            guard end + marker.count < characters.count,
                  Array(characters[end..<end + marker.count]) == marker,
                  NumberParser.isDigit(characters[end + marker.count]) else { continue }
            return parser.number(at: end + marker.count)
        }
        return nil
    }

    /// `a mile`, `two cups`: a number word and a spelled-out unit.
    private func worded(at start: Int) -> ScannedQuantity? {
        var end = start
        while end < characters.count, characters[end].isLetter { end += 1 }
        let word = String(characters[start..<end]).lowercased()
        guard let value = Self.numberWords[word],
              let unit = UnitMatcher(characters: characters).match(after: end, wordsOnly: true) else { return nil }
        let number = WrittenNumber(
            value: value, decimals: 0, isNominal: true, text: String(characters[start..<end]),
            trailingZeros: 0, endsInFive: false
        )
        return ScannedQuantity(low: make(number, start: start, unit: unit, wordsOnly: true), high: nil, end: unit.end)
    }

    private func make(_ number: WrittenNumber, start: Int, unit: UnitMatcher.Match, wordsOnly: Bool) -> Quantity {
        let separator = unit.isAttached ? "" : (unit.isHyphenated ? "-" : " ")
        return Quantity(
            number: number, unitText: unit.text, sizes: unit.alias.sizes,
            text: number.text + separator + unit.text, offsets: start..<unit.end
        )
    }

    /// Marks every character inside fenced (```) or inline (`) code.
    static func codeMask(_ characters: [Character]) -> [Bool] {
        var mask = [Bool](repeating: false, count: characters.count)
        var fenced = false
        var inline = false
        var index = 0
        while index < characters.count {
            if index + 2 < characters.count, characters[index...index + 2].allSatisfy({ $0 == "`" }) {
                fenced.toggle()
                for offset in 0..<3 { mask[index + offset] = true }
                index += 3
                continue
            }
            if characters[index] == "`", !fenced { inline.toggle() }
            if characters[index] == "\n" { inline = false }
            mask[index] = fenced || inline || characters[index] == "`"
            index += 1
        }
        return mask
    }
}
