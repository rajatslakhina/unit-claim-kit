import Foundation

/// Finds the unit conversions an answer states, outside code: `5 km (3.1 miles)`, `1 inch = 2.54 cm`,
/// `120 miles, or about 190 km`, `5–10 km (3–6 mi)`, `a cup of flour is 120 g`.
public struct ConversionReader: Sendable {
    /// Where a volume-to-mass conversion finds its density.
    public var densities: DensityTable

    public init(densities: DensityTable = .common) {
        self.densities = densities
    }

    public func claims(in text: String) -> [ConversionClaim] {
        let context = TextContext(characters: Array(text), densities: densities)
        let spans = QuantityScanner(context.characters).quantities()
        var claims: [ConversionClaim] = []
        var listed: Set<Int> = []
        for index in spans.indices.dropLast() where !listed.contains(index + 1) {
            let source = spans[index]
            guard let link = Link.between(context.gap(source.end, spans[index + 1].start)) else { continue }
            claims += context.pair(source, spans[index + 1], link)
            guard link.isParenthetical else { continue }
            var last = spans[index + 1]
            for further in spans.indices.dropFirst(index + 2) {
                guard let more = Link.within(context.gap(last.end, spans[further].start)) else { break }
                claims += context.pair(source, spans[further], more)
                listed.insert(further)
                last = spans[further]
            }
        }
        return claims
    }
}

/// The text a claim is read from, and what its sentence says about it.
struct TextContext {
    let characters: [Character]
    let densities: DensityTable

    static let changeWords: Set = [
        "by", "rise", "rises", "rose", "risen", "raise", "raises", "raised", "increase", "increases",
        "increased", "drop", "drops", "dropped", "fall", "falls", "fell", "swing", "swings", "difference",
        "change", "changes", "changed", "delta", "warmer", "cooler", "colder", "hotter", "higher", "lower",
        "warming", "cooling", "gain", "gains"
    ]

    func gap(_ start: Int, _ end: Int) -> String {
        String(characters[start..<end])
    }

    /// Claims between two quantities joined by `link`: one, or one per end of two ranges.
    func pair(_ source: ScannedQuantity, _ target: ScannedQuantity, _ link: Link) -> [ConversionClaim] {
        var ends = [(source.low, target.low)]
        switch (source.high, target.high) {
        case let (sourceHigh?, targetHigh?):
            ends.append((sourceHigh, targetHigh))
        case (nil, nil):
            break
        default:
            return []
        }
        let excerpt = excerptEnd(after: target.end, parenthetical: link.isParenthetical)
        return ends.compactMap { pair in
            claim(pair.0, pair.1, link, excerpt: source.start..<excerpt)
        }
    }

    private func claim(_ source: Quantity, _ target: Quantity, _ link: Link, excerpt: Range<Int>) -> ConversionClaim? {
        guard source.unit.converts(to: target.unit), source.sizes != target.sizes,
              !link.isWeak || plausibleAlternative(source, target) else { return nil }
        let sentence = sentence(around: excerpt)
        let isTemperature = source.dimension == .temperature
        return ConversionClaim(
            source: source, target: target, isApproximate: link.isApproximate || target.number.isNominal,
            isDifference: isTemperature && marksChange(excerpt, in: sentence),
            substance: source.dimension == target.dimension
                ? nil : substance(named: link.subject, near: excerpt, in: sentence),
            excerpt: String(characters[excerpt])
        )
    }

    /// A bare "or" or "/" joins a conversion only across systems and within a factor of three.
    private func plausibleAlternative(_ source: Quantity, _ target: Quantity) -> Bool {
        let systems: Set = [source.unit.system, target.unit.system]
        guard systems == [.metric, .customary] else { return false }
        guard source.dimension == target.dimension, source.dimension != .temperature else { return true }
        let expected = Converter.convert(source.number.value, from: source.unit, to: target.unit, reading: .point)
        let ratio = target.number.value / expected
        return ratio >= Decimal(1) / 3 && ratio <= 3
    }

    /// Takes in a closing parenthesis after the last target.
    private func excerptEnd(after end: Int, parenthetical: Bool) -> Int {
        guard parenthetical else { return end }
        var index = end
        while index < characters.count, characters[index] == " " { index += 1 }
        return index < characters.count && characters[index] == ")" ? index + 1 : end
    }
}
