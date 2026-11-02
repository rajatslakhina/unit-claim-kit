import Foundation

/// Something measured by volume in one place and by weight in another, with the range of densities
/// it is usually given. A range, not a value: a cup of flour weighs 120 g spooned and more scooped.
public struct Substance: Sendable, Hashable {
    public let name: String
    /// Lowercase words that name it in an answer ("all-purpose flour", "flour").
    public let names: [String]
    /// Grams per millilitre.
    public let density: ClosedRange<Decimal>

    public init(_ name: String, names: [String] = [], gramsPerMillilitre density: ClosedRange<Decimal>) {
        self.name = name
        self.names = ([name] + names).map { $0.lowercased() }
        self.density = density
    }
}

/// The substances a mass-to-volume conversion can be checked against.
public struct DensityTable: Sendable, Hashable {
    public var substances: [Substance]

    public init(_ substances: [Substance]) {
        self.substances = substances
    }

    /// The same table with more substances; a later entry wins where names overlap.
    public func adding(_ more: [Substance]) -> DensityTable {
        DensityTable(more + substances)
    }

    /// Common kitchen ingredients, with ranges wide enough for the usual published weights per US cup
    /// (flour 120 to 140 g, sugar about 200 g, butter 227 g). Replace or extend it for other domains.
    public static let common = DensityTable([
        Substance("water", gramsPerMillilitre: range("0.997", "1.0")),
        Substance("milk", gramsPerMillilitre: range("1.026", "1.035")),
        Substance("flour", names: ["all-purpose flour", "plain flour", "bread flour"],
                  gramsPerMillilitre: range("0.50", "0.60")),
        Substance("sugar", names: ["granulated sugar", "white sugar", "caster sugar"],
                  gramsPerMillilitre: range("0.83", "0.86")),
        Substance("brown sugar", gramsPerMillilitre: range("0.88", "0.93")),
        Substance("butter", gramsPerMillilitre: range("0.94", "0.97")),
        Substance("honey", gramsPerMillilitre: range("1.36", "1.45")),
        Substance("oil", names: ["olive oil", "vegetable oil"], gramsPerMillilitre: range("0.91", "0.93")),
        Substance("rice", gramsPerMillilitre: range("0.78", "0.85")),
        Substance("salt", names: ["table salt"], gramsPerMillilitre: range("1.15", "1.30"))
    ])

    /// No substances: every volume-to-mass conversion is left unchecked.
    public static let empty = DensityTable([])

    private static func range(_ low: String, _ high: String) -> ClosedRange<Decimal> {
        Decimal.exactly(low)...Decimal.exactly(high)
    }

    /// Every name in the table, longest first, with the substance it names.
    var names: [(name: [Character], substance: Substance)] {
        let all = substances.flatMap { substance in substance.names.map { (name: Array($0), substance: substance) } }
        return all.enumerated()
            .sorted { ($0.element.name.count, $1.offset) > ($1.element.name.count, $0.offset) }
            .map(\.element)
    }
}
