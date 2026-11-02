/// Everything one answer's unit conversions came to.
public struct ConversionReport: Sendable, Hashable {
    public enum Verdict: String, Sendable, Hashable, CaseIterable {
        /// No conversion stated.
        case noConversions
        /// Every conversion holds.
        case verified
        /// Nothing wrong, but a volume-to-mass conversion could not be checked.
        case unchecked
        /// Nothing wrong, but a value is misrounded, loose, or holds only for another size of a unit.
        case caution
        /// At least one conversion is wrong.
        case wrong
    }

    public let findings: [ConversionFinding]
    public let verdict: Verdict

    public init(findings: [ConversionFinding]) {
        self.findings = findings
        switch findings.map(\.severity).max() {
        case nil:
            verdict = .noConversions
        case .holds?:
            verdict = .verified
        case .unchecked?:
            verdict = .unchecked
        case .caution?:
            verdict = .caution
        case .wrong?:
            verdict = .wrong
        }
    }

    /// The findings that need a correction or a second look.
    public var flagged: [ConversionFinding] {
        findings.filter { $0.severity >= .caution }
    }

    /// Flagged findings that were already flagged earlier in the conversation.
    public var repeatedCount: Int {
        flagged.filter(\.isRepeated).count
    }

    /// One sentence per flagged finding, with the right value.
    public var corrections: [String] {
        flagged.map(\.explanation)
    }

    /// A note for the person reading the answer; `nil` when nothing is flagged.
    public var note: String? {
        guard !flagged.isEmpty else { return nil }
        let again = repeatedCount > 0 ? " Some of this was stated again after a correction was asked for." : ""
        return "Unit check: " + corrections.joined(separator: " ") + again
    }

    /// A message asking the model to redo its conversions; `nil` when there is nothing to redo.
    public var feedback: String? {
        guard !flagged.isEmpty else { return nil }
        let lines = corrections.map { "- " + $0 }.joined(separator: "\n")
        return "Some unit conversions in your answer do not hold:\n" + lines
            + "\nRedo each one with the exact conversion factor, correct every figure that depends on it, "
            + "and keep the rest of the answer as it is."
    }

    /// A short line for a trace or a log.
    public var summary: String {
        guard !findings.isEmpty else { return "no conversions stated" }
        let counts = Dictionary(grouping: findings, by: \.severity).mapValues(\.count)
        let noun = findings.count == 1 ? "conversion" : "conversions"
        var parts = ["\(findings.count) \(noun) checked", "\(counts[.holds, default: 0]) hold"]
        if let unchecked = counts[.unchecked] { parts.append("\(unchecked) unchecked") }
        if let caution = counts[.caution] { parts.append("\(caution) to check") }
        if let wrong = counts[.wrong] { parts.append("\(wrong) wrong") }
        if repeatedCount > 0 { parts.append("\(repeatedCount) repeated") }
        return parts.joined(separator: ", ")
    }
}
