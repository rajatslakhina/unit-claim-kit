@testable import UnitClaimKit
import XCTest

final class ReportTests: XCTestCase {
    func testVerdicts() {
        let checker = UnitClaimChecker()
        XCTAssertEqual(checker.check("No units here.").verdict, .noConversions)
        XCTAssertEqual(checker.check("5 km (3.1 mi)").verdict, .verified)
        XCTAssertEqual(checker.check("2 cups of stock (480 g)").verdict, .unchecked)
        XCTAssertEqual(checker.check("6 ft = 1.82 m").verdict, .caution)
        XCTAssertEqual(checker.check("5 miles (3.1 km)").verdict, .wrong)
        XCTAssertEqual(ConversionReport.Verdict.allCases.count, 5)
        XCTAssertTrue(ConversionFinding.Severity.holds < .wrong)
    }

    func testNotesAndFeedback() {
        let clean = UnitClaimChecker().check("5 km (3.1 mi) and 2 cups of stock (480 g)")
        XCTAssertNil(clean.note)
        XCTAssertNil(clean.feedback)
        XCTAssertEqual(clean.summary, "2 conversions checked, 1 hold, 1 unchecked")
        XCTAssertEqual(UnitClaimChecker().check("Nothing.").summary, "no conversions stated")
        let report = UnitClaimChecker().check("5 miles (3.1 km), 6 ft = 1.82 m, 1 lb (16 oz)")
        XCTAssertEqual(report.summary, "3 conversions checked, 1 hold, 1 to check, 1 wrong")
        XCTAssertEqual(report.flagged.count, 2)
        XCTAssertEqual(report.note, "Unit check: " + report.corrections.joined(separator: " "))
        XCTAssertEqual(report.feedback, """
            Some unit conversions in your answer do not hold:
            - 5 miles is 8.05 km, not 3.1 km. 3.1 km applies the conversion factor the wrong way round.
            - 6 ft is 1.8288 m, which rounds to 1.83 m, not 1.82 m.
            Redo each one with the exact conversion factor, correct every figure that depends on it, \
            and keep the rest of the answer as it is.
            """)
        XCTAssertEqual(UnitClaimChecker().check("5 km (3.1 mi)").summary, "1 conversion checked, 1 hold")
    }

    func testExplanations() {
        XCTAssertEqual(explanations("5 km (3.1 mi), A 10K is 10 km (6.5 miles), 1 gallon (4.5 L)"), [
            "5 km is 3.1 mi, which holds.",
            "10 km is 6.21 miles, so 6.5 miles is off by 0.286 miles without being marked as approximate.",
            "1 gallon is 3.79 L with the US gallon; 4.5 L holds only with the imperial gallon."
        ])
        XCTAssertEqual(explanations("It got 10°C (50°F) warmer. 1 m³ (3.3 cu ft). 2 cups of flour (500 g)."), [
            "As a change, 10°C is 18°F, not 50°F. 50°F converts it as a reading, adding the offset between the scales.",
            "1 m³ is 35.3 cu ft, not 3.3 cu ft. 3.3 cu ft uses the length factor where the cube of it applies.",
            "2 cups of flour is 237 to 284 g, not 500 g. 500 g weighs 2 cups of flour as if it were water."
        ])
        XCTAssertEqual(explanations("5 g (500 mg), 2 cups of stock (480 g), 3,000 m (9,000 ft)"), [
            "5 g is 5000 mg, not 500 mg. 500 mg is off by a factor of 10.",
            "2 cups to 480 g turns a volume into a mass, which depends on what is measured, "
                + "and nothing named next to it has a known density.",
            "3,000 m is 9,843 ft, not 9,000 ft."
        ])
        XCTAssertEqual(explanations("5 kg (5,000,000 mg)"), ["5 kg is 5,000,000 mg, which holds."])
        XCTAssertEqual(explanations("Water boils at 100°C (180°F)."), [
            "100°C is 212°F, not 180°F. 180°F leaves out the offset between the scales, "
                + "which only a change in temperature would."
        ])
        XCTAssertEqual(explanations("50 m² (164 sq ft)"), [
            "50 m² is 538 sq ft, not 164 sq ft. 164 sq ft uses the length factor where the square of it applies."
        ])
        XCTAssertEqual(explanations("1 g (1,000,000 mg)"), [
            "1 g is 1,000 mg, not 1,000,000 mg. 1,000,000 mg is off by a factor of 1,000."
        ])
    }

    func testDecimalText() {
        XCTAssertEqual(DecimalText.grouped("-1234567.5"), "-1,234,567.5")
        XCTAssertEqual(DecimalText.grouped("123"), "123")
        XCTAssertEqual(DecimalText.fixed(.of("2.5"), minimumPlaces: 3), "2.500")
        XCTAssertEqual(DecimalText.significantPlaces(0), 0)
        XCTAssertEqual(DecimalText.significantPlaces(.of("0.000123")), 4)
    }
}
