import Foundation

/// How strictly a stated conversion is held to its exact value.
public struct ConversionPolicy: Sendable, Hashable {
    /// How far an approximate or round figure may be from the exact value, relative to it.
    public var approximateTolerance: Decimal
    /// The same for temperatures, in kelvins (a relative error means nothing near 0°C).
    public var temperatureTolerance: Decimal
    /// Whether a value off by its last digit (`6 ft = 1.82 m`) is reported, or let through.
    public var flagsMisrounding: Bool
    /// Whether a value that holds only for another size of the unit (an imperial gallon, a binary
    /// gigabyte) is let through instead of reported.
    public var acceptsOtherConventions: Bool

    public init(
        approximateTolerance: Decimal = Decimal(sign: .plus, exponent: -2, significand: 5),
        temperatureTolerance: Decimal = 5,
        flagsMisrounding: Bool = true,
        acceptsOtherConventions: Bool = false
    ) {
        self.approximateTolerance = approximateTolerance
        self.temperatureTolerance = temperatureTolerance
        self.flagsMisrounding = flagsMisrounding
        self.acceptsOtherConventions = acceptsOtherConventions
    }

    /// Round figures and approximations within 5% (5 K for temperatures); misrounding and other
    /// conventions reported.
    public static let standard = ConversionPolicy()

    /// Within 10% (8 K); misrounding and other conventions let through.
    public static let lenient = ConversionPolicy(
        approximateTolerance: Decimal(sign: .plus, exponent: -1, significand: 1), temperatureTolerance: 8,
        flagsMisrounding: false, acceptsOtherConventions: true
    )

    /// A value must round to the digits it gives, approximate or not.
    public static let strict = ConversionPolicy(approximateTolerance: 0, temperatureTolerance: 0)
}
