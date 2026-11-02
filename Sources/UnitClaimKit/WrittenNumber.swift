import Foundation

/// A number as an answer wrote it, with how precisely it was written.
///
/// `quantum` is one step in the last written digit (`3.1` is 0.1, `240` is 1). `coarseQuantum` is
/// the step a round figure may stand for: `1,600` may be rounded to hundreds and `175` to fives, so
/// "1 mile (1,600 m)" and "350°F (175°C)" read as rounded, within the policy's tolerance.
public struct WrittenNumber: Sendable, Hashable {
    public let value: Decimal
    /// Digits written after the decimal point.
    public let decimals: Int
    /// Written as a fraction (`1/2`, `½`) or a word (`a`, `two`): as close as the writer could say it.
    public let isNominal: Bool
    /// The text as written.
    public let text: String
    /// Zeros ending a whole number (`1,600` has two).
    let trailingZeros: Int
    /// The last digit that is not one of those zeros is a 5 (`175`, `250`, `2.5`).
    let endsInFive: Bool

    /// One step in the last written digit.
    public var quantum: Decimal { .power10(-decimals) }

    /// The coarsest step the number may have been rounded to.
    var coarseQuantum: Decimal {
        let place = decimals > 0 ? Decimal.power10(-decimals) : .power10(trailingZeros)
        return endsInFive ? place * 5 : place
    }

    /// Whether `separator` grouping was used in the digits (`1,600`).
    var isGrouped: Bool { text.contains(",") }
}

/// Reads numbers: `-40`, `1,609.34`, `.5`, `1/2`, `½`, `1 ½`, `1 1/2`.
struct NumberParser {
    struct Parsed {
        let number: WrittenNumber
        let end: Int
    }

    let characters: [Character]

    static let fractions: [Character: (Decimal, Decimal)] = [
        "½": (1, 2), "⅓": (1, 3), "⅔": (2, 3), "¼": (1, 4), "¾": (3, 4), "⅛": (1, 8), "⅜": (3, 8), "⅝": (5, 8),
        "⅞": (7, 8)
    ]

    static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    func number(at start: Int) -> Parsed? {
        var index = start
        let negative = index + 1 < characters.count && "-−".contains(characters[index])
            && (Self.isDigit(characters[index + 1]) || Self.fractions[characters[index + 1]] != nil)
        if negative { index += 1 }
        if let fraction = vulgarValue(at: index) {
            return Parsed(number: nominal(fraction, from: start, to: index + 1), end: index + 1)
        }
        guard let whole = digits(at: index) else { return nil }
        if let mixed = mixedFraction(after: whole.end) {
            return Parsed(number: nominal(whole.value + mixed.value, from: start, to: mixed.end), end: mixed.end)
        }
        if let ratio = simpleFraction(numerator: whole) {
            return Parsed(number: nominal(ratio.value, from: start, to: ratio.end), end: ratio.end)
        }
        let value = negative ? -whole.value : whole.value
        let number = WrittenNumber(
            value: value, decimals: whole.decimals, isNominal: false, text: text(start, whole.end),
            trailingZeros: whole.trailingZeros, endsInFive: whole.endsInFive
        )
        return Parsed(number: number, end: whole.end)
    }

    private func text(_ start: Int, _ end: Int) -> String {
        String(characters[start..<end])
    }

    private func nominal(_ value: Decimal, from start: Int, to end: Int) -> WrittenNumber {
        let negative = "-−".contains(characters[start])
        return WrittenNumber(
            value: negative ? -value : value, decimals: 0, isNominal: true, text: text(start, end),
            trailingZeros: 0, endsInFive: false
        )
    }

}
