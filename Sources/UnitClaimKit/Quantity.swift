/// A number with a unit, as an answer wrote it: `5 km`, `350°F`, `a mile`, `2 cups`.
public struct Quantity: Sendable, Hashable {
    public let number: WrittenNumber
    /// The unit as written: `km`, `°F`, `cups`.
    public let unitText: String
    /// What the unit can mean, the usual size first. Never empty.
    public let sizes: [UnitDefinition]
    /// The quantity as written.
    public let text: String
    /// Character offsets of the quantity in the text it was read from.
    public let offsets: Range<Int>

    public var dimension: Dimension { sizes[0].dimension }

    /// The usual size of the unit.
    public var unit: UnitDefinition { sizes[0] }
}

/// One quantity or a range written with one unit (`5–10 km`), where each end is a quantity.
struct ScannedQuantity {
    let low: Quantity
    let high: Quantity?
    var start: Int { low.offsets.lowerBound }
    let end: Int
}
