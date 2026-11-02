import Foundation

/// What a stated conversion turned out to be once the conversion was done exactly.
public struct ConversionFinding: Sendable, Hashable {
    public enum Outcome: Sendable, Hashable {
        /// The exact value.
        case exact
        /// The exact value rounded to the digits written, or to the round figure written.
        case rounded
        /// Marked approximate (or written as a fraction) and within the policy's tolerance.
        case approximate
        /// Within the range the substance's density allows.
        case plausible
        /// Within one step of the last written digit, but not how the value rounds.
        case misrounded(correct: Decimal)
        /// Within tolerance, but neither rounded to its digits nor marked approximate.
        case loose(correct: Decimal)
        /// Holds only for another size of a unit (`used`), where the usual one (`instead`) was meant.
        case otherConvention(used: [String], instead: [String])
        case wrong(correct: Decimal, slip: Slip?)
        /// A volume and a mass, with nothing named whose density is known.
        case needsDensity
    }

    /// A recognizable mistake behind a wrong value.
    public enum Slip: Sendable, Hashable {
        /// The factor applied the wrong way round (`5 miles = 3.1 km`).
        case inverted
        /// A temperature difference converted as a reading, offset included (`10°C warmer = 50°F warmer`).
        case offsetAdded
        /// A temperature reading converted without the offset (`100°C = 180°F`).
        case offsetDropped
        /// An area or volume converted with the length factor (`1 m² = 3.28 ft²`).
        case lengthFactor
        /// A volume of something else weighed as if it were water (`2 cups of flour = 500 g`).
        case waterDensity
        /// Off by a power of ten (`500 mg = 5 g`); the exponent is how far.
        case powerOfTen(Int)
    }

    public enum Severity: Int, Sendable, Hashable, Comparable {
        case holds
        /// Could not be checked.
        case unchecked
        case caution
        case wrong

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public let claim: ConversionClaim
    public let outcome: Outcome
    public let severity: Severity
    /// The exact value or range of the conversion; `nil` when it needs a density nobody gave.
    public let expected: Expected?
    /// Flagged in an earlier review of the same conversation (set by `ConversionLedger`).
    public internal(set) var isRepeated = false

    /// Identifies the same claim across rewrites: both quantities, without spacing or case.
    var key: String {
        (claim.statement + "=" + claim.claimedText).lowercased().filter { !$0.isWhitespace }
    }
}

extension ConversionFinding.Outcome {
    /// How close a fit is, for choosing among conventions: exact first, then rounded, then approximate.
    var rank: Int {
        switch self {
        case .exact: 0
        case .rounded, .plausible: 1
        default: 2
        }
    }
}
