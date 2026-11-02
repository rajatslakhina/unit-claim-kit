import Foundation

/// Exact conversions between unit sizes.
enum Converter {
    /// A temperature is a reading (with the offset between scales) or a difference (without it).
    enum Reading: Sendable, Hashable {
        case point
        case difference
    }

    /// `value` in `source`, expressed in `target`. Multiplies before it divides, so a conversion
    /// whose result terminates (`100°C` to `212°F`) comes out exact.
    static func convert(_ value: Decimal, from source: UnitDefinition, to target: UnitDefinition,
                        reading: Reading) -> Decimal {
        let inOffset = reading == .point ? source.offset : 0
        let outOffset = reading == .point ? target.offset : 0
        let scaled = (value + inOffset) * source.numerator * target.denominator
        return scaled / (source.denominator * target.numerator) - outOffset
    }

    /// The range `value` covers in `target` when a volume and a mass are converted through `density`.
    static func convert(_ value: Decimal, from source: UnitDefinition, to target: UnitDefinition,
                        density: ClosedRange<Decimal>) -> Expected {
        let base = value * source.numerator / source.denominator
        let ends = source.dimension == .volume
            ? [base * density.lowerBound, base * density.upperBound]
            : [base / density.upperBound, base / density.lowerBound]
        let converted = ends.map { $0 * target.denominator / target.numerator }
        return Expected(converted[0], converted[1])
    }
}

/// The value a conversion should give: one number, or a range when it goes through a density.
public struct Expected: Sendable, Hashable {
    public let low: Decimal
    public let high: Decimal

    init(_ low: Decimal, _ high: Decimal) {
        self.low = min(low, high)
        self.high = max(low, high)
    }

    init(_ value: Decimal) {
        self.init(value, value)
    }

    public var isExact: Bool { low == high }

    /// How far `value` lies outside the range; zero inside it.
    func distance(to value: Decimal) -> Decimal {
        value < low ? low - value : (value > high ? value - high : 0)
    }

    /// The end of the range nearest `value`, or `value` itself inside it.
    func nearest(to value: Decimal) -> Decimal {
        min(max(value, low), high)
    }

    func scaled(by factor: Decimal) -> Expected {
        Expected(low * factor, high * factor)
    }
}
