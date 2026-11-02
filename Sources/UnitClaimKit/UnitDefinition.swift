import Foundation

/// What a unit measures. A quantity converts into another of the same dimension, and a volume and
/// a mass convert into each other through a density.
public enum Dimension: String, Sendable, Hashable, CaseIterable {
    case length
    case area
    case volume
    case mass
    case temperature
    case time
    case speed
    case data
    case energy
    case pressure
    case power
}

/// The measuring system a unit belongs to. A bare "or" between two quantities is read as a
/// conversion only when they come from different systems ("5 km or 3.1 miles", not "2 cups or 3 tbsp").
public enum MeasuringSystem: String, Sendable, Hashable {
    case metric
    case customary
    /// Units both systems use: seconds, bytes.
    case shared
}

/// One size a unit can have.
///
/// A size is a fraction of its dimension's base unit (metre, square metre, millilitre, gram, kelvin,
/// second, metre per second, byte, joule, pascal, watt), plus an offset for temperature scales:
/// base = (value + offset) × numerator ÷ denominator. Keeping the fraction whole lets `°F`, which is
/// 5/9 of a kelvin, convert exactly.
public struct UnitDefinition: Sendable, Hashable {
    /// How explanations name this size: `km`, `US gallon`, `imperial gallon`.
    public let name: String
    public let dimension: Dimension
    public let system: MeasuringSystem
    let numerator: Decimal
    let denominator: Decimal
    let offset: Decimal
    /// For an area or a volume built from a length unit (`ft²`, `m³`), that length unit in metres.
    let length: Decimal?

    init(
        _ name: String,
        _ dimension: Dimension,
        _ system: MeasuringSystem,
        _ numerator: Decimal,
        per denominator: Decimal = 1,
        offset: Decimal = 0,
        length: Decimal? = nil
    ) {
        self.name = name
        self.dimension = dimension
        self.system = system
        self.numerator = numerator
        self.denominator = denominator
        self.offset = offset
        self.length = length
    }

    /// Whether quantities in the two units can be compared: the same dimension, or a volume and a mass.
    func converts(to other: UnitDefinition) -> Bool {
        dimension == other.dimension || Set([dimension, other.dimension]) == [.volume, .mass]
    }
}

extension Decimal {
    /// Ten to the power `exponent`, exactly.
    static func power10(_ exponent: Int) -> Decimal {
        Decimal(sign: .plus, exponent: exponent, significand: 1)
    }

    /// An exact decimal from its digits (a `Decimal` float literal goes through `Double`).
    static func exactly(_ text: String) -> Decimal {
        NSDecimalNumber(string: text, locale: Locale(identifier: "en_US_POSIX")).decimalValue
    }

    /// The nearest multiple of `quantum`, ties away from zero.
    func rounded(toMultipleOf quantum: Decimal) -> Decimal {
        var ratio = self / quantum
        var whole = Decimal()
        NSDecimalRound(&whole, &ratio, 0, .plain)
        return whole * quantum
    }
}
