import Foundation

/// Recomputes a stated conversion exactly and says what the stated value is.
///
/// The order matters: a value that rounds, or is a round figure or a marked approximation within
/// tolerance, holds. Otherwise it may be off by its last digit, hold only for another size of the
/// unit, hold only as the other temperature reading, or be close but unmarked. Anything else is
/// wrong, with the mistake named when the value fits a known one.
public struct ConversionEvaluator: Sendable {
    public let policy: ConversionPolicy

    public init(policy: ConversionPolicy = .standard) {
        self.policy = policy
    }

    public func judge(_ claim: ConversionClaim) -> ConversionFinding {
        let reading: Converter.Reading = claim.isDifference ? .difference : .point
        guard let expected = expected(claim, claim.source.unit, claim.target.unit, reading) else {
            return finding(claim, .needsDensity, nil)
        }
        let outcome = fit(claim, expected)
            ?? misrounded(claim, expected)
            ?? otherConvention(claim, reading)
            ?? temperatureSlip(claim, expected, reading)
            ?? loose(claim, expected)
            ?? .wrong(correct: expected.nearest(to: claim.target.number.value), slip: slip(claim))
        return finding(claim, outcome, expected)
    }

    private func finding(_ claim: ConversionClaim, _ outcome: ConversionFinding.Outcome,
                         _ expected: Expected?) -> ConversionFinding {
        ConversionFinding(claim: claim, outcome: outcome, severity: severity(of: outcome), expected: expected)
    }

    func severity(of outcome: ConversionFinding.Outcome) -> ConversionFinding.Severity {
        switch outcome {
        case .exact, .rounded, .approximate, .plausible:
            return .holds
        case .needsDensity:
            return .unchecked
        case .misrounded:
            return policy.flagsMisrounding ? .caution : .holds
        case .otherConvention:
            return policy.acceptsOtherConventions ? .holds : .caution
        case .loose:
            return .caution
        case .wrong:
            return .wrong
        }
    }

    /// The value the conversion should give with these sizes; `nil` for a volume and a mass with no density.
    private func expected(_ claim: ConversionClaim, _ source: UnitDefinition, _ target: UnitDefinition,
                          _ reading: Converter.Reading) -> Expected? {
        let value = claim.source.number.value
        guard claim.needsDensity else {
            return Expected(Converter.convert(value, from: source, to: target, reading: reading))
        }
        return claim.substance.map { Converter.convert(value, from: source, to: target, density: $0.density) }
    }

    /// Exact, rounded to its digits or to its round figure, or a marked approximation within tolerance.
    func fit(_ claim: ConversionClaim, _ expected: Expected) -> ConversionFinding.Outcome? {
        let number = claim.target.number
        let error = expected.distance(to: number.value)
        // A fraction or a number word has no last digit to round to: it is exact, or approximate.
        if error <= (number.isNominal ? 0 : number.quantum / 2) {
            guard expected.isExact else { return .plausible }
            return error == 0 ? .exact : .rounded
        }
        guard error <= tolerance(claim, expected) else { return nil }
        if !number.isNominal, error <= number.coarseQuantum / 2 { return .rounded }
        return claim.isApproximate ? .approximate : nil
    }

    private func tolerance(_ claim: ConversionClaim, _ expected: Expected) -> Decimal {
        let target = claim.target.unit
        guard target.dimension == .temperature else {
            return policy.approximateTolerance * expected.nearest(to: claim.target.number.value).magnitude
        }
        return policy.temperatureTolerance * target.denominator / target.numerator
    }

    private func misrounded(_ claim: ConversionClaim, _ expected: Expected) -> ConversionFinding.Outcome? {
        let number = claim.target.number
        guard expected.isExact, !number.isNominal, expected.distance(to: number.value) < number.quantum else {
            return nil
        }
        return .misrounded(correct: expected.low.rounded(toMultipleOf: number.quantum))
    }

    private func loose(_ claim: ConversionClaim, _ expected: Expected) -> ConversionFinding.Outcome? {
        let value = claim.target.number.value
        guard expected.distance(to: value) <= tolerance(claim, expected) else { return nil }
        return .loose(correct: expected.nearest(to: value))
    }
}

extension ConversionEvaluator {
    /// Holds for some other combination of the two units' sizes; the closest fit wins.
    private func otherConvention(_ claim: ConversionClaim,
                                 _ reading: Converter.Reading) -> ConversionFinding.Outcome? {
        let usual = (claim.source.unit, claim.target.unit)
        var best: (closeness: (rank: Int, error: Decimal), outcome: ConversionFinding.Outcome)?
        for source in claim.source.sizes {
            for target in claim.target.sizes where source != usual.0 || target != usual.1 {
                guard let expected = expected(claim, source, target, reading), let fit = fit(claim, expected) else {
                    continue
                }
                let error = expected.distance(to: claim.target.number.value)
                if let best, best.closeness <= (fit.rank, error) { continue }
                let changed = [(source, usual.0), (target, usual.1)].filter { $0.0 != $0.1 }
                let outcome = ConversionFinding.Outcome.otherConvention(
                    used: changed.map(\.0.name), instead: changed.map(\.1.name)
                )
                best = ((fit.rank, error), outcome)
            }
        }
        return best?.outcome
    }

    /// Holds only as the other temperature reading: a difference converted as a reading, or the reverse.
    private func temperatureSlip(_ claim: ConversionClaim, _ expected: Expected,
                                 _ reading: Converter.Reading) -> ConversionFinding.Outcome? {
        guard claim.source.dimension == .temperature else { return nil }
        let other: Converter.Reading = reading == .point ? .difference : .point
        let value = Converter.convert(claim.source.number.value, from: claim.source.unit, to: claim.target.unit,
                                      reading: other)
        guard fit(claim, Expected(value)) != nil else { return nil }
        return .wrong(correct: expected.low, slip: reading == .point ? .offsetDropped : .offsetAdded)
    }

    /// The mistake a wrong value fits, if any.
    private func slip(_ claim: ConversionClaim) -> ConversionFinding.Slip? {
        let (source, target) = (claim.source.unit, claim.target.unit)
        let value = claim.source.number.value
        if claim.needsDensity { return weighedAsWater(claim) }
        guard source.dimension != .temperature else { return nil }
        let inverse = Converter.convert(value, from: target, to: source, reading: .difference)
        if fit(claim, Expected(inverse)) != nil { return .inverted }
        if let from = source.length, let to = target.length, fit(claim, Expected(value * from / to)) != nil {
            return .lengthFactor
        }
        let exact = Expected(Converter.convert(value, from: source, to: target, reading: .difference))
        let exponents = [1, 2, 3, 6, 9, -1, -2, -3, -6, -9]
        for exponent in exponents where fit(claim, exact.scaled(by: .power10(exponent))) != nil {
            return .powerOfTen(exponent)
        }
        return nil
    }

    private func weighedAsWater(_ claim: ConversionClaim) -> ConversionFinding.Slip? {
        let water = Decimal(1)...Decimal(1)
        for source in claim.source.sizes {
            for target in claim.target.sizes {
                let expected = Converter.convert(claim.source.number.value, from: source, to: target, density: water)
                if fit(claim, expected) != nil { return .waterDensity }
            }
        }
        return nil
    }
}
