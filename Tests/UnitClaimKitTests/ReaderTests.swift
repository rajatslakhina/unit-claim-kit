@testable import UnitClaimKit
import XCTest

final class ReaderTests: XCTestCase {
    func testLinks() {
        XCTAssertEqual(read("The race is 5 km (3.1 miles) long."), ["5 km = 3.1 miles"])
        XCTAssertEqual(read("1 inch = 2.54 cm = 25.4 mm"), ["1 inch = 2.54 cm", "2.54 cm = 25.4 mm"])
        XCTAssertEqual(read("The drive is 120 miles, or about 190 km."), ["120 miles = 190 km"])
        XCTAssertEqual(read("5 km is about 3 miles; 1 mile ≈ 1.6 km; 1 lb → 454 g."),
                       ["5 km = 3 miles", "1 mile = 1.6 km", "1 lb = 454 g"])
        XCTAssertEqual(read("2 cups of flour (250 g). A 1 TB drive is 931 GB. A cup of sugar weighs 200 g."),
                       ["2 cups = 250 g", "1 TB = 931 GB", "A cup = 200 g"])
        XCTAssertEqual(read("5 km, which is roughly 3.1 miles, and 10 km (~6.2 mi)"),
                       ["5 km = 3.1 miles", "10 km = 6.2 mi"])
        XCTAssertEqual(read("A mile is 1.6 km, two cups (473 ml), a 10-mile (16 km) hike"),
                       ["A mile = 1.6 km", "two cups = 473 ml", "10-mile = 16 km"])
    }

    func testApproximateMarks() {
        let claims = ConversionReader().claims(in: "5 km (about 3 mi), 5 km (3 mi), 5 km ≈ 3 mi, 1 L (1 ½ cups)")
        XCTAssertEqual(claims.map(\.isApproximate), [true, false, true, true])
        XCTAssertEqual(claims.first?.excerpt, "5 km (about 3 mi)")
        XCTAssertFalse(claims[0].needsDensity)
    }

    func testNumbers() {
        XCTAssertEqual(read("1,609.34 m (1 mile), 1/2 cup (118 ml), ½ cup (118 ml), 1 ½ cups (355 ml)"),
                       ["1,609.34 m = 1 mile", "1/2 cup = 118 ml", "½ cup = 118 ml", "1 ½ cups = 355 ml"])
        XCTAssertEqual(read("1 1/2 cups (355 ml), 1½ cups (355 ml), -40°C (−40°F), .5 L (500 mL)"),
                       ["1 1/2 cups = 355 ml", "1½ cups = 355 ml", "-40°C = −40°F", ".5 L = 500 mL"])
        let mixed = ConversionReader().claims(in: "1 1/2 cups (355 ml)")
        XCTAssertEqual(mixed.first?.source.number.value, .of("1.5"))
        XCTAssertEqual(mixed.first?.source.number.isNominal, true)
        XCTAssertEqual(read("1,5 km (1 mile), 24/7 km (1 mile), 3/0 cups (1 L), 1,2345 km (1 mi)"), [])
        XCTAssertEqual(read("v2 km (1 mi), 1.5.2 km (1 mi), 12 1.5/2 cups (1 L)"), [])
    }

    func testRanges() {
        XCTAssertEqual(read("Runs of 5–10 km (3–6 miles) or 5 to 10 km (3 to 6 miles)"),
                       ["5 km = 3 miles", "10 km = 6 miles", "5 km = 3 miles", "10 km = 6 miles"])
        XCTAssertEqual(read("5-10 km (6 miles), 5 km (3 - 6 miles)"), [])
    }

    func testParentheticalLists() {
        XCTAssertEqual(read("5 km (3.1 mi / 5,000 m) and 1 kg (2.2 lb, 35 oz)"),
                       ["5 km = 3.1 mi", "5 km = 5,000 m", "1 kg = 2.2 lb", "1 kg = 35 oz"])
        XCTAssertEqual(read("5 km (3.1 mi), 8 km later"), ["5 km = 3.1 mi"])
    }

    func testUnits() {
        XCTAssertEqual(read("350º F (175 ºC), 10 Mb (1.25 MB), 50 sq ft (4.6 m²), 3 fl oz (89 mL)"),
                       ["350º F = 175 ºC", "10 Mb = 1.25 MB", "50 sq ft = 4.6 m²", "3 fl oz = 89 mL"])
        XCTAssertEqual(read("12 in (30 cm), 12 in. (30 cm), 60 km/h (37 mph), 1 kWh (3.6 MJ), 30 psi (2 bar)"),
                       ["12 in = 30 cm", "12 in. = 30 cm", "60 km/h = 37 mph", "1 kWh = 3.6 MJ", "30 psi = 2 bar"])
        XCTAssertEqual(read("100 hp (75 kW), 1 nautical mile (1.852 km), 1 kcal (4.184 kJ), 1 atm (101 kPa)"),
                       ["100 hp = 75 kW", "1 nautical mile = 1.852 km", "1 kcal = 4.184 kJ", "1 atm = 101 kPa"])
        XCTAssertEqual(read("10 mb (1.25 MB), 5 in the morning (12 cm), 5 kmx (3 mi), 5 -km (3 mi), 5 -C (41 F)"), [])
        XCTAssertEqual(read("Add 5  km (3 mi), 5 C, 5-m (16 ft), height 12 in "), [])
        XCTAssertEqual(read("The total is 1,600"), [])
        XCTAssertEqual(read("A 10 km run, which for an American is 6.2 miles. 60 km in 1 hour. A 5K run, 3t (3 kg)."), [])
        XCTAssertEqual(read("-½°C (31.1°F)"), ["-½°C = 31.1°F"])
    }

    func testWhatIsLeftAlone() {
        let text = """
            Splits: 5 km, 10 km and 21.1 km. Train for 5 km or 10 miles. Add 2 cups or 3 tbsp.
            The drive is 300 km (4 hours). Choose 16 GB (or 32 GB). The 1990s (2000s).
            ```
            let route = "5 km (3 mi)"
            ```
            Inline `5 km (3 mi)` code. 5 km is not 3 miles. 5 km to 3 miles. 5 km, not 3 miles. 1 day or 24 hours.
            """
        XCTAssertEqual(read(text), [])
    }

    func testWeakLinks() {
        XCTAssertEqual(read("5 km or 3.1 miles, 20°C or 68°F, 1 cup or 240 g, 5 km / 3.1 mi"),
                       ["5 km = 3.1 miles", "20°C = 68°F", "1 cup = 240 g", "5 km = 3.1 mi"])
    }

    func testSubstances() {
        let reader = ConversionReader()
        let named = reader.claims(in: "Use 1 cup of rice (185 g) and 2 cups of stock (480 g).")
        XCTAssertEqual(named.map { $0.substance?.name }, ["rice", nil])
        let after = reader.claims(in: "Add 1 cup (240 g) brown sugar, then 1 cup (120 g) all-purpose flour.")
        XCTAssertEqual(after.map { $0.substance?.name }, ["brown sugar", "flour"])
        let before = reader.claims(in: "Flour: 1 cup (120 g). Sugar - 1 cup (200 g). Honey\n1 cup (340 g)")
        XCTAssertEqual(before.map { $0.substance?.name }, ["flour", "sugar", nil])
        let elsewhere = reader.claims(in: "Honey is sweet. Then 1 cup (340 g) of it.")
        XCTAssertEqual(elsewhere.map { $0.substance?.name }, [nil])
        XCTAssertNil(ConversionReader(densities: .empty).claims(in: "1 cup of flour (120 g)").first?.substance)
        XCTAssertTrue(named[0].needsDensity)
    }

    func testDifferenceCue() {
        let claims = ConversionReader().claims(
            in: "It rose by 10°C (18°F). It is 5°C (9°F) warmer. Boil at 100°C (212°F). 5 km (3 mi) higher."
        )
        XCTAssertEqual(claims.map(\.isDifference), [true, true, false, false])
    }

    func testQuantityDetails() {
        let claim = ConversionReader().claims(in: "a 10-mile (16 km) hike")[0]
        XCTAssertEqual(claim.source.unitText, "mile")
        XCTAssertEqual(claim.source.unit, UnitCatalog.mile)
        XCTAssertEqual(claim.source.offsets, 2..<9)
        XCTAssertEqual(claim.target.dimension, .length)
        XCTAssertEqual(claim.statement, "10-mile")
        XCTAssertEqual(claim.claimedText, "16 km")
        XCTAssertEqual(Dimension.allCases.count, 11)
    }
}
