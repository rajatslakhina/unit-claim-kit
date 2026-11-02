/// A conversion an answer states: one quantity said to equal another in a different unit.
public struct ConversionClaim: Sendable, Hashable {
    /// The quantity being converted: the first one written.
    public let source: Quantity
    /// The value the answer gives for it, the one that is checked.
    public let target: Quantity
    /// Marked as approximate (`about`, `~`, `≈`).
    public let isApproximate: Bool
    /// A temperature read as a change ("10°C warmer", "a rise of 5°F"), which converts without the
    /// offset between the scales.
    public let isDifference: Bool
    /// What is measured, when a volume is converted to a mass or back.
    public let substance: Substance?
    /// The text from the first quantity to the end of the second.
    public let excerpt: String

    /// The quantity converted, as written: `350°F`.
    public var statement: String { source.text }

    /// The value given for it, as written: `175°C`.
    public var claimedText: String { target.text }

    /// Whether the two sides are a volume and a mass.
    public var needsDensity: Bool { source.dimension != target.dimension }
}
