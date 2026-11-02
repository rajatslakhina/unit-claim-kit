import Foundation

extension ConversionFinding {
    /// One sentence on this finding, with the right value where there is one.
    public var explanation: String {
        let source = claim.statement + substanceText
        let claimed = claim.claimedText
        guard let expected else {
            return "\(claim.statement) to \(claimed) turns a volume into a mass, which depends on what is measured, "
                + "and nothing named next to it has a known density."
        }
        let exact = expectedText(expected)
        switch outcome {
        case let .misrounded(correct):
            let precise = text(expected.low, extraPlaces: 2)
            return "\(source) is \(precise), which rounds to \(text(correct)), not \(claimed)."
        case .loose:
            let gap = text(expected.distance(to: claim.target.number.value))
            return "\(source) is \(exact), so \(claimed) is off by \(gap) without being marked as approximate."
        case let .otherConvention(used, instead):
            return "\(source) is \(exact) with the \(instead.joined(separator: " and the ")); "
                + "\(claimed) holds only with the \(used.joined(separator: " and the "))."
        case let .wrong(_, slip):
            let change = slip == .offsetAdded ? "As a change, " : ""
            return "\(change)\(source) is \(exact), not \(claimed)." + (slip.map { sentence($0, source) } ?? "")
        default:
            return "\(source) is \(claimed), which holds."
        }
    }

    private var substanceText: String {
        claim.substance.map { " of \($0.name)" } ?? ""
    }

    /// The exact value, or the range a density allows.
    private func expectedText(_ expected: Expected) -> String {
        guard !expected.isExact else { return text(expected.low) }
        return DecimalText.number(expected.low, like: claim.target) + " to " + text(expected.high)
    }

    private func text(_ value: Decimal, extraPlaces: Int = 0) -> String {
        DecimalText.text(value, like: claim.target, extraPlaces: extraPlaces)
    }

    private func sentence(_ slip: Slip, _ source: String) -> String {
        let claimed = claim.claimedText
        switch slip {
        case .inverted:
            return " \(claimed) applies the conversion factor the wrong way round."
        case .offsetAdded:
            return " \(claimed) converts it as a reading, adding the offset between the scales."
        case .offsetDropped:
            return " \(claimed) leaves out the offset between the scales, which only a change in temperature would."
        case .lengthFactor:
            let power = claim.source.dimension == .area ? "square" : "cube"
            return " \(claimed) uses the length factor where the \(power) of it applies."
        case .waterDensity:
            return " \(claimed) weighs \(source) as if it were water."
        case let .powerOfTen(exponent):
            let factor = DecimalText.grouped(DecimalText.fixed(.power10(abs(exponent)), minimumPlaces: 0))
            return " \(claimed) is off by a factor of \(factor)."
        }
    }
}
