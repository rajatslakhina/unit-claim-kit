import UnitClaimKit

/// Printing for the demo: one line per stated conversion, then the verdict.
enum Out {
    static func heading(_ number: Int, _ title: String) {
        print("")
        print("[\(number)] \(title)")
    }

    static func line(_ text: String) {
        print("    " + text)
    }

    static func quote(_ label: String, _ text: String) {
        line("\(label): \"\(text)\"")
    }

    static func report(_ report: ConversionReport) {
        for finding in report.findings {
            line("\(mark(finding.severity)) \(finding.claim.excerpt)  ->  \(label(finding.outcome))")
        }
        line("verdict: \(report.verdict.rawValue) (\(report.summary))")
    }

    static func block(_ label: String, _ text: String?) {
        guard let text else { return }
        line(label + ":")
        for row in text.split(separator: "\n") { line("  " + row) }
    }

    static func corrections(_ report: ConversionReport) {
        for correction in report.corrections { line("- " + correction) }
    }

    private static func mark(_ severity: ConversionFinding.Severity) -> String {
        switch severity {
        case .holds: "ok"
        case .unchecked: "--"
        case .caution: "??"
        case .wrong: "XX"
        }
    }

    private static func label(_ outcome: ConversionFinding.Outcome) -> String {
        switch outcome {
        case .exact: "exact"
        case .rounded: "rounded as written"
        case .approximate: "approximate, within tolerance"
        case .plausible: "within the density range"
        case .misrounded: "misrounded"
        case .loose: "close, but not marked approximate"
        case let .otherConvention(used, _): "holds only for the " + used.joined(separator: " and the ")
        case let .wrong(_, slip?): "wrong (\(name(slip)))"
        case .wrong: "wrong"
        case .needsDensity: "unchecked: no density"
        }
    }

    private static func name(_ slip: ConversionFinding.Slip) -> String {
        switch slip {
        case .inverted: "factor inverted"
        case .offsetAdded: "change converted as a reading"
        case .offsetDropped: "offset left out"
        case .lengthFactor: "length factor on an area"
        case .waterDensity: "weighed as water"
        case let .powerOfTen(exponent): "off by 10^\(exponent)"
        }
    }
}
