/// Reads an answer's unit conversions and judges every one: the one call most callers need.
public struct UnitClaimChecker: Sendable {
    public let policy: ConversionPolicy
    public let reader: ConversionReader

    public init(policy: ConversionPolicy = .standard, densities: DensityTable = .common) {
        self.policy = policy
        reader = ConversionReader(densities: densities)
    }

    public func claims(in text: String) -> [ConversionClaim] {
        reader.claims(in: text)
    }

    public func check(_ text: String) -> ConversionReport {
        let evaluator = ConversionEvaluator(policy: policy)
        return ConversionReport(findings: claims(in: text).map(evaluator.judge))
    }
}

/// Checks a conversation's answers one after another and remembers what it flagged, so a wrong
/// conversion stated again after a correction was asked for is marked as repeated rather than new.
public actor ConversionLedger {
    public struct Statistics: Sendable, Hashable {
        public var reviews = 0
        public var conversions = 0
        public var flagged = 0
        public var repeated = 0
    }

    public nonisolated let checker: UnitClaimChecker
    public private(set) var statistics = Statistics()
    private var flaggedKeys: Set<String> = []

    public init(checker: UnitClaimChecker = UnitClaimChecker()) {
        self.checker = checker
    }

    public func review(_ text: String) -> ConversionReport {
        var findings = checker.check(text).findings
        var keys: Set<String> = []
        for index in findings.indices where findings[index].severity >= .caution {
            let key = findings[index].key
            findings[index].isRepeated = flaggedKeys.contains(key)
            keys.insert(key)
        }
        flaggedKeys.formUnion(keys)
        let report = ConversionReport(findings: findings)
        statistics.reviews += 1
        statistics.conversions += findings.count
        statistics.flagged += report.flagged.count
        statistics.repeated += report.repeatedCount
        return report
    }

    /// Starts a new conversation: nothing flagged so far counts as a repeat.
    public func forget() {
        flaggedKeys.removeAll()
    }
}
