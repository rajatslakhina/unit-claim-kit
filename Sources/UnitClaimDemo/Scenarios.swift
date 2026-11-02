import Foundation
import UnitClaimKit

enum Scenarios {
    static func recipe() {
        Out.heading(1, "A recipe, converted for a metric kitchen")
        let answer = "Preheat the oven to 350°F (175°C). Whisk 2 cups of flour (500 g) with 1 cup of sugar (200 g) "
            + "and 1/2 cup of butter (113 g), then add 1 cup of milk (250 ml)."
        Out.quote("answer", answer)
        let report = UnitClaimChecker().check(answer)
        Out.report(report)
        Out.block("feedback to the model", report.feedback)
        let rewrite = "Preheat the oven to 350°F (175°C). Whisk 2 cups of flour (250 g) with 1 cup of sugar (200 g) "
            + "and 1/2 cup of butter (113 g), then add 1 cup of milk (240 ml)."
        Out.quote("rewrite", rewrite)
        Out.report(UnitClaimChecker().check(rewrite))
    }

    static func distances() {
        Out.heading(2, "Distances, heights and speeds")
        let answer = "The trail is 10 km (6.2 miles) and climbs 800 m (2,600 ft) to a summit at 3,000 m (9,000 ft). "
            + "The drive is 120 miles, or about 190 km, at 100 km/h (62 mph). The hut is 5 miles (3.1 km) away, "
            + "up a 6 ft = 1.82 m step."
        Out.quote("answer", answer)
        let report = UnitClaimChecker().check(answer)
        Out.report(report)
        Out.corrections(report)
    }

    static func temperatures() {
        Out.heading(3, "Temperatures: readings and changes")
        let answer = "Water boils at 100°C (212°F) and freezes at 0°C (32°F); -40°C is -40°F. "
            + "Tomorrow will be 10°C (50°F) warmer. In Fahrenheit, a 100°C oven is 180°F."
        Out.quote("answer", answer)
        let report = UnitClaimChecker().check(answer)
        Out.report(report)
        Out.corrections(report)
    }

    static func conventions() {
        Out.heading(4, "Which gallon, which gigabyte, which ton")
        let answer = "A 1 TB drive is 931 GB. A 1 gallon (4.5 L) tin covers a room, "
            + "and the pallet weighs 1 ton (1,000 kg)."
        Out.quote("answer", answer)
        let standard = UnitClaimChecker().check(answer)
        Out.report(standard)
        Out.corrections(standard)
        let lenient = UnitClaimChecker(policy: .lenient).check(answer)
        Out.line("under .lenient: \(lenient.verdict.rawValue) (\(lenient.summary))")
    }

    static func areas() {
        Out.heading(5, "Areas, and powers of ten")
        let answer = "The flat is 50 m² (164 sq ft), the garden 2 hectares (5 acres), and the tablet is 500 mg (5 g)."
        Out.quote("answer", answer)
        let report = UnitClaimChecker().check(answer)
        Out.report(report)
        Out.corrections(report)
    }

    static func densities() {
        Out.heading(6, "Volume to weight needs a density")
        let answer = "Use 1 cup of rice (185 g) and 2 cups of stock (480 g)."
        Out.quote("answer", answer)
        let report = UnitClaimChecker().check(answer)
        Out.report(report)
        Out.line(report.findings.last?.explanation ?? "")
        let stock = Substance("stock", names: ["broth"], gramsPerMillilitre: 1...Decimal(102) / 100)
        let extended = UnitClaimChecker(densities: DensityTable.common.adding([stock])).check(answer)
        Out.line("with stock added to the table:")
        Out.report(extended)
    }

    static func leftAlone() {
        Out.heading(7, "What is left alone")
        let answer = """
            - Splits: 5 km, 10 km and 21.1 km.
            - Train for 5 km or 10 miles, whichever suits.
            - The drive is 300 km (4 hours).
            - Choose 16 GB (or 32 GB).
            ```swift
            let route = "5 km (3 mi)"
            ```
            """
        for row in answer.split(separator: "\n") { Out.line("| " + row) }
        let claims = UnitClaimChecker().claims(in: answer)
        Out.line("conversions read: \(claims.count) (a list, two alternatives, a time, the same unit twice, code)")
    }

    static func conversation() async {
        Out.heading(8, "A conversation: the same mistake twice")
        let ledger = ConversionLedger()
        let turns = [
            "A marathon is 42.195 km (26.2 miles) and a 10K is 10 km (6.8 miles).",
            "You're right to ask. A 10K is 10 km (6.8 miles), so about a quarter of a marathon.",
            "Correction: a 10K is 10 km (6.2 miles)."
        ]
        for (number, turn) in turns.enumerated() {
            Out.quote("turn \(number + 1)", turn)
            let report = await ledger.review(turn)
            Out.report(report)
            if report.repeatedCount > 0 { Out.line(report.note ?? "") }
        }
        let statistics = await ledger.statistics
        Out.line("ledger: \(statistics.reviews) reviews, \(statistics.conversions) conversions, "
            + "\(statistics.flagged) flagged, \(statistics.repeated) repeated")
    }
}
