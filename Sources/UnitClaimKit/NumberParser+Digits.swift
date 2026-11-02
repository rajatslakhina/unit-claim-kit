import Foundation

extension NumberParser {
    struct Digits {
        let value: Decimal
        let decimals: Int
        let trailingZeros: Int
        let endsInFive: Bool
        let hasPoint: Bool
        let end: Int
    }

    struct Fraction {
        let value: Decimal
        let end: Int
    }

    /// Digits with optional groups of three after commas and an optional decimal part.
    func digits(at start: Int) -> Digits? {
        var whole = ""
        var index = start
        while index < characters.count, Self.isDigit(characters[index]) {
            whole.append(characters[index])
            index += 1
        }
        if (1...3).contains(whole.count) {
            while groupFollows(at: index) {
                whole += String(characters[index + 1...index + 3])
                index += 4
            }
        }
        var fraction = ""
        if index + 1 < characters.count, characters[index] == ".", Self.isDigit(characters[index + 1]) {
            index += 1
            while index < characters.count, Self.isDigit(characters[index]) {
                fraction.append(characters[index])
                index += 1
            }
        }
        guard !whole.isEmpty || !fraction.isEmpty else { return nil }
        let significant = (whole + fraction).drop { $0 == "0" }
        let trailing = fraction.isEmpty ? whole.reversed().prefix { $0 == "0" }.count : 0
        let lastDigit = fraction.isEmpty ? whole.dropLast(trailing).last : fraction.last
        return Digits(
            value: .exactly((whole.isEmpty ? "0" : whole) + (fraction.isEmpty ? "" : "." + fraction)),
            decimals: fraction.count,
            trailingZeros: significant.isEmpty ? 0 : trailing,
            endsInFive: lastDigit == "5",
            hasPoint: !fraction.isEmpty,
            end: index
        )
    }

    /// `,` followed by exactly three digits and then something that is not a digit.
    private func groupFollows(at index: Int) -> Bool {
        guard index + 3 < characters.count, characters[index] == "," else { return false }
        let group = characters[index + 1...index + 3]
        let after = index + 4 < characters.count ? characters[index + 4] : " "
        return group.allSatisfy(Self.isDigit) && !Self.isDigit(after)
    }

    /// `1 1/2` or `1 ½` or `1½` after a whole number.
    func mixedFraction(after end: Int) -> Fraction? {
        var index = end
        if index < characters.count, characters[index] == " " { index += 1 }
        if let value = vulgarValue(at: index) { return Fraction(value: value, end: index + 1) }
        guard index > end, let top = digits(at: index) else { return nil }
        return simpleFraction(numerator: top)
    }

    /// `3/4`: a proper fraction with a denominator up to 64, so `24/7` and dates are left alone.
    func simpleFraction(numerator: Digits) -> Fraction? {
        let slash = numerator.end
        guard !numerator.hasPoint, slash + 1 < characters.count, characters[slash] == "/",
              let bottom = digits(at: slash + 1), !bottom.hasPoint, bottom.value <= 64,
              numerator.value < bottom.value else { return nil }
        return Fraction(value: numerator.value / bottom.value, end: bottom.end)
    }

    func vulgarValue(at index: Int) -> Decimal? {
        guard index < characters.count, let (top, bottom) = Self.fractions[characters[index]] else { return nil }
        return top / bottom
    }
}
