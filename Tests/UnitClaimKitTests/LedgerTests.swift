@testable import UnitClaimKit
import XCTest

final class LedgerTests: XCTestCase {
    func testRepeatsAcrossAConversation() async {
        let ledger = ConversionLedger()
        let first = await ledger.review("A 10K is 10 km (6.8 miles), and 5 km (3.1 mi).")
        XCTAssertEqual(first.repeatedCount, 0)
        let second = await ledger.review("Sorry: a 10K is 10 km (6.8 Miles).")
        XCTAssertEqual(second.repeatedCount, 1)
        XCTAssertEqual(second.flagged.map(\.isRepeated), [true])
        XCTAssertEqual(second.summary, "1 conversion checked, 0 hold, 1 wrong, 1 repeated")
        XCTAssertTrue(second.note?.hasSuffix("Some of this was stated again after a correction was asked for.") == true)
        let fixed = await ledger.review("A 10K is 10 km (6.2 miles).")
        XCTAssertEqual(fixed.verdict, .verified)
        let statistics = await ledger.statistics
        XCTAssertEqual(statistics, ConversionLedger.Statistics(reviews: 3, conversions: 4, flagged: 2, repeated: 1))
        await ledger.forget()
        let fresh = await ledger.review("A 10K is 10 km (6.8 miles).")
        XCTAssertEqual(fresh.repeatedCount, 0)
        XCTAssertEqual(ledger.checker.policy, .standard)
    }

    func testDensityTable() {
        let mine = Substance("flour", gramsPerMillilitre: 2...3)
        let table = DensityTable.common.adding([mine])
        XCTAssertEqual(table.names.first { $0.name == Array("flour") }?.substance, mine)
        XCTAssertEqual(DensityTable.empty.substances, [])
        XCTAssertEqual(mine.names, ["flour"])
        XCTAssertEqual(UnitClaimChecker(densities: .empty).check("1 cup of flour (120 g)").verdict, .unchecked)
    }
}
