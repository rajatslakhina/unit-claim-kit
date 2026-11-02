@testable import UnitClaimKit
import XCTest

final class EvaluatorTests: XCTestCase {
    func testHolds() {
        XCTAssertEqual(outcomes("1 inch = 2.54 cm, 100°C (212°F), 1 lb (16 oz), 0°C (273.15 kelvin)"),
                       [.exact, .exact, .exact, .exact])
        XCTAssertEqual(outcomes("5 km (3.1 mi), 1 mile (1,600 m), 350°F (175°C), 180°C (350°F), 1 cup (240 ml)"),
                       [.rounded, .rounded, .rounded, .rounded, .rounded])
        XCTAssertEqual(outcomes("100 km is about 63 miles, 350 mL (1 ½ cups)"), [.approximate, .approximate])
        XCTAssertEqual(outcomes("1 cup of flour (125 g), 100 g of sugar (1/2 cup)"), [.plausible, .plausible])
        XCTAssertEqual(outcomes("It rose by 10°C (18°F)."), [.exact])
    }

    func testCloseCalls() {
        XCTAssertEqual(outcomes("6 ft = 1.82 m"), [.misrounded(correct: .of("1.83"))])
        XCTAssertEqual(UnitClaimChecker(policy: .lenient).check("6 ft = 1.82 m").verdict, .verified)
        XCTAssertEqual(outcomes("A 10K is 10 km (6.5 miles)."), [.loose(correct: .of("6.2137119223733396961743418436331"))])
        guard case let .wrong(correct, nil) = outcomes("1 L (1/4 gallon)")[0] else { return XCTFail("1/4 gallon") }
        XCTAssertLessThan((correct - .of("0.26417")).magnitude, .of("0.00001"))
    }

    func testOtherConventions() {
        XCTAssertEqual(outcomes("1 gallon (4.5 L)"), [.otherConvention(used: ["imperial gallon"], instead: ["US gallon"])])
        XCTAssertEqual(outcomes("1 ton (1,000 kg)"),
                       [.otherConvention(used: ["metric tonne (1,000 kg)"], instead: ["short ton (2,000 lb)"])])
        XCTAssertEqual(outcomes("8 GB (8,192 MB)"), [
            .otherConvention(used: ["binary GB (2^30 bytes)", "binary MB (2^20 bytes)"],
                             instead: ["decimal GB (10^9 bytes)", "decimal MB (10^6 bytes)"])
        ])
        XCTAssertEqual(outcomes("1 cup of water (250 g)"),
                       [.otherConvention(used: ["metric cup (250 mL)"], instead: ["US cup"])])
        XCTAssertEqual(UnitClaimChecker(policy: .lenient).check("1 gallon (4.5 L)").verdict, .verified)
        XCTAssertEqual(outcomes("1 ton (about 1,010 kg)"),
                       [.otherConvention(used: ["long ton (2,240 lb)"], instead: ["short ton (2,000 lb)"])])
        XCTAssertEqual(outcomes("-½°C (31.1°F)"), [.exact])
    }

    func testSlips() {
        let slips = UnitClaimChecker().check(
            "5 miles (3.1 km). Boil at 100°C (180°F). It got 10°C (50°F) warmer. 50 m² (164 sq ft). "
                + "1 m³ (3.3 cu ft). 2 cups of flour (500 g). 500 mg (5 g). 5 g (500 mg). 3,000 m (9,000 ft)."
        ).findings.map { finding -> ConversionFinding.Slip? in
            guard case let .wrong(_, slip) = finding.outcome else { return nil }
            return slip
        }
        XCTAssertEqual(slips, [
            .inverted, .offsetDropped, .offsetAdded, .lengthFactor, .lengthFactor, .waterDensity, .powerOfTen(1),
            .powerOfTen(-1), nil
        ])
    }

    func testDensity() {
        XCTAssertEqual(outcomes("2 cups of stock (480 g)"), [.needsDensity])
        XCTAssertEqual(UnitClaimChecker().check("2 cups of stock (480 g)").findings.first?.severity, .unchecked)
        XCTAssertEqual(outcomes("1 cup of honey (100 g)"), [.wrong(correct: .of("321.76000164"), slip: nil)])
        let stock = Substance("stock", gramsPerMillilitre: 1...Decimal(102) / 100)
        let checker = UnitClaimChecker(densities: DensityTable.common.adding([stock]))
        XCTAssertEqual(checker.check("2 cups of stock (480 g)").verdict, .verified)
    }

    func testStrictPolicy() {
        let strict = outcomes("350°F (175°C), 5 km (3.1 mi)", policy: .strict)
        guard case let .wrong(correct, nil) = strict[0] else { return XCTFail("\(strict)") }
        XCTAssertLessThan((correct - .of("176.6667")).magnitude, .of("0.001"))
        XCTAssertEqual(strict[1], .rounded)
        XCTAssertEqual(ConversionPolicy.standard, ConversionPolicy())
        XCTAssertEqual(ConversionEvaluator().policy, .standard)
    }

    func testExpected() {
        let range = Expected(.of("3"), .of("1"))
        XCTAssertEqual(range.low, 1)
        XCTAssertEqual(range.distance(to: 0), 1)
        XCTAssertEqual(range.distance(to: 5), 2)
        XCTAssertEqual(range.nearest(to: 2), 2)
        XCTAssertFalse(range.isExact)
        XCTAssertEqual(range.scaled(by: 10), Expected(10, 30))
    }
}
