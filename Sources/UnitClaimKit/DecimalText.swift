import Foundation

/// Writes a value the way the answer wrote its number: at least its decimals, enough digits to be
/// useful (three significant figures, up to four decimals), its grouping, and its unit.
enum DecimalText {
    static func text(_ value: Decimal, like quantity: Quantity, extraPlaces: Int = 0) -> String {
        let separator = quantity.text.dropFirst(quantity.number.text.count).prefix { $0 == " " || $0 == "-" }
        return number(value, like: quantity, extraPlaces: extraPlaces) + (separator.isEmpty ? "" : " ")
            + quantity.unitText
    }

    /// The digits alone.
    static func number(_ value: Decimal, like quantity: Quantity, extraPlaces: Int = 0) -> String {
        let written = quantity.number
        let places = max(written.decimals, significantPlaces(value)) + extraPlaces
        let digits = fixed(value.rounded(toMultipleOf: .power10(-places)), minimumPlaces: written.decimals)
        return written.isGrouped ? grouped(digits) : digits
    }

    /// Decimals needed for three significant figures, between none and four.
    static func significantPlaces(_ value: Decimal) -> Int {
        let magnitude = NSDecimalNumber(decimal: value.magnitude).doubleValue
        guard magnitude > 0 else { return 0 }
        return min(4, max(0, 2 - Int(log10(magnitude).rounded(.down))))
    }

    /// The value with at least `minimumPlaces` decimals, and no trailing zeros beyond them.
    static func fixed(_ value: Decimal, minimumPlaces: Int) -> String {
        let plain = NSDecimalNumber(decimal: value).stringValue
        let parts = plain.split(separator: ".", omittingEmptySubsequences: false)
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        let padding = String(repeating: "0", count: max(0, minimumPlaces - fraction.count))
        let decimals = fraction + padding
        return String(parts[0]) + (decimals.isEmpty ? "" : "." + decimals)
    }

    /// Thousands separated by commas.
    static func grouped(_ text: String) -> String {
        let negative = text.hasPrefix("-")
        let unsigned = negative ? String(text.dropFirst()) : text
        let parts = unsigned.split(separator: ".", omittingEmptySubsequences: false)
        var whole = String(parts[0])
        var index = whole.count - 3
        while index > 0 {
            whole.insert(",", at: whole.index(whole.startIndex, offsetBy: index))
            index -= 3
        }
        let fraction = parts.count > 1 ? "." + parts[1] : ""
        return (negative ? "-" : "") + whole + fraction
    }
}
