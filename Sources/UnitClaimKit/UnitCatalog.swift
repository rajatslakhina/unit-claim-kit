import Foundation

/// The unit sizes this package knows, by dimension. Where one word has several sizes (a gallon, a
/// cup, a ton, a gigabyte), the usual one comes first and the others are kept as conventions an
/// answer may have meant.
enum UnitCatalog {
    private static func d(_ text: String) -> Decimal { .exactly(text) }

    // Length, in metres.
    static let metre = UnitDefinition("m", .length, .metric, 1)
    static let kilometre = UnitDefinition("km", .length, .metric, 1000)
    static let centimetre = UnitDefinition("cm", .length, .metric, d("0.01"))
    static let millimetre = UnitDefinition("mm", .length, .metric, d("0.001"))
    static let micrometre = UnitDefinition("µm", .length, .metric, d("0.000001"))
    static let inch = UnitDefinition("in", .length, .customary, d("0.0254"))
    static let foot = UnitDefinition("ft", .length, .customary, d("0.3048"))
    static let yard = UnitDefinition("yd", .length, .customary, d("0.9144"))
    static let mile = UnitDefinition("mile", .length, .customary, d("1609.344"))
    static let nauticalMile = UnitDefinition("nautical mile", .length, .customary, 1852)

    // Area, in square metres.
    static let squareMetre = UnitDefinition("m²", .area, .metric, 1, length: 1)
    static let squareKilometre = UnitDefinition("km²", .area, .metric, 1_000_000, length: 1000)
    static let squareCentimetre = UnitDefinition("cm²", .area, .metric, d("0.0001"), length: d("0.01"))
    static let squareInch = UnitDefinition("in²", .area, .customary, d("0.00064516"), length: d("0.0254"))
    static let squareFoot = UnitDefinition("ft²", .area, .customary, d("0.09290304"), length: d("0.3048"))
    static let squareYard = UnitDefinition("yd²", .area, .customary, d("0.83612736"), length: d("0.9144"))
    static let squareMile = UnitDefinition("mi²", .area, .customary, d("2589988.110336"), length: d("1609.344"))
    static let acre = UnitDefinition("acre", .area, .customary, d("4046.8564224"))
    static let hectare = UnitDefinition("hectare", .area, .metric, 10000)

    // Volume, in millilitres.
    static let millilitre = UnitDefinition("mL", .volume, .metric, 1)
    static let centilitre = UnitDefinition("cL", .volume, .metric, 10)
    static let decilitre = UnitDefinition("dL", .volume, .metric, 100)
    static let litre = UnitDefinition("L", .volume, .metric, 1000)
    static let cubicMetre = UnitDefinition("m³", .volume, .metric, 1_000_000, length: 1)
    static let cubicCentimetre = UnitDefinition("cm³", .volume, .metric, 1, length: d("0.01"))
    static let cubicInch = UnitDefinition("in³", .volume, .customary, d("16.387064"), length: d("0.0254"))
    static let cubicFoot = UnitDefinition("ft³", .volume, .customary, d("28316.846592"), length: d("0.3048"))
    static let usTeaspoon = UnitDefinition("US teaspoon", .volume, .customary, d("4.92892159375"))
    static let metricTeaspoon = UnitDefinition("metric teaspoon (5 mL)", .volume, .metric, 5)
    static let usTablespoon = UnitDefinition("US tablespoon", .volume, .customary, d("14.78676478125"))
    static let metricTablespoon = UnitDefinition("metric tablespoon (15 mL)", .volume, .metric, 15)
    static let usFluidOunce = UnitDefinition("US fluid ounce", .volume, .customary, d("29.5735295625"))
    static let imperialFluidOunce = UnitDefinition("imperial fluid ounce", .volume, .customary, d("28.4130625"))
    static let usCup = UnitDefinition("US cup", .volume, .customary, d("236.5882365"))
    static let usLegalCup = UnitDefinition("US legal cup (240 mL)", .volume, .customary, 240)
    static let metricCup = UnitDefinition("metric cup (250 mL)", .volume, .metric, 250)
    static let imperialCup = UnitDefinition("imperial cup", .volume, .customary, d("284.130625"))
    static let usPint = UnitDefinition("US pint", .volume, .customary, d("473.176473"))
    static let imperialPint = UnitDefinition("imperial pint", .volume, .customary, d("568.26125"))
    static let usQuart = UnitDefinition("US quart", .volume, .customary, d("946.352946"))
    static let imperialQuart = UnitDefinition("imperial quart", .volume, .customary, d("1136.5225"))
    static let usGallon = UnitDefinition("US gallon", .volume, .customary, d("3785.411784"))
    static let imperialGallon = UnitDefinition("imperial gallon", .volume, .customary, d("4546.09"))

    // Mass, in grams.
    static let microgram = UnitDefinition("µg", .mass, .metric, d("0.000001"))
    static let milligram = UnitDefinition("mg", .mass, .metric, d("0.001"))
    static let gram = UnitDefinition("g", .mass, .metric, 1)
    static let kilogram = UnitDefinition("kg", .mass, .metric, 1000)
    static let ounce = UnitDefinition("oz", .mass, .customary, d("28.349523125"))
    static let pound = UnitDefinition("lb", .mass, .customary, d("453.59237"))
    static let stone = UnitDefinition("stone", .mass, .customary, d("6350.29318"))
    static let shortTon = UnitDefinition("short ton (2,000 lb)", .mass, .customary, d("907184.74"))
    static let longTon = UnitDefinition("long ton (2,240 lb)", .mass, .customary, d("1016046.9088"))
    static let tonne = UnitDefinition("metric tonne (1,000 kg)", .mass, .metric, 1_000_000)

    // Temperature, in kelvins.
    static let kelvin = UnitDefinition("K", .temperature, .metric, 1)
    static let celsius = UnitDefinition("°C", .temperature, .metric, 1, offset: d("273.15"))
    static let fahrenheit = UnitDefinition("°F", .temperature, .customary, 5, per: 9, offset: d("459.67"))

    // Time, in seconds.
    static let millisecond = UnitDefinition("ms", .time, .shared, d("0.001"))
    static let second = UnitDefinition("s", .time, .shared, 1)
    static let minute = UnitDefinition("min", .time, .shared, 60)
    static let hour = UnitDefinition("h", .time, .shared, 3600)
    static let day = UnitDefinition("day", .time, .shared, 86400)
    static let week = UnitDefinition("week", .time, .shared, 604_800)
}

extension UnitCatalog {
    // Speed, in metres per second.
    static let metrePerSecond = UnitDefinition("m/s", .speed, .metric, 1)
    static let kilometrePerHour = UnitDefinition("km/h", .speed, .metric, 5, per: 18)
    static let milePerHour = UnitDefinition("mph", .speed, .customary, d("0.44704"))
    static let knot = UnitDefinition("knot", .speed, .customary, 463, per: 900)
    static let footPerSecond = UnitDefinition("ft/s", .speed, .customary, d("0.3048"))

    // Data, in bytes.
    static let bit = UnitDefinition("bit", .data, .shared, 1, per: 8)
    static let megabit = UnitDefinition("Mb", .data, .shared, 125_000)
    static let gigabit = UnitDefinition("Gb", .data, .shared, 125_000_000)
    static let byte = UnitDefinition("B", .data, .shared, 1)
    static let kilobyte = UnitDefinition("decimal kB (1,000 bytes)", .data, .shared, 1000)
    static let megabyte = UnitDefinition("decimal MB (10^6 bytes)", .data, .shared, 1_000_000)
    static let gigabyte = UnitDefinition("decimal GB (10^9 bytes)", .data, .shared, 1_000_000_000)
    static let terabyte = UnitDefinition("decimal TB (10^12 bytes)", .data, .shared, d("1000000000000"))
    static let kibibyte = UnitDefinition("binary KB (1,024 bytes)", .data, .shared, 1024)
    static let mebibyte = UnitDefinition("binary MB (2^20 bytes)", .data, .shared, 1_048_576)
    static let gibibyte = UnitDefinition("binary GB (2^30 bytes)", .data, .shared, 1_073_741_824)
    static let tebibyte = UnitDefinition("binary TB (2^40 bytes)", .data, .shared, d("1099511627776"))

    // Energy, in joules.
    static let joule = UnitDefinition("J", .energy, .metric, 1)
    static let kilojoule = UnitDefinition("kJ", .energy, .metric, 1000)
    static let megajoule = UnitDefinition("MJ", .energy, .metric, 1_000_000)
    static let calorie = UnitDefinition("small calorie (4.184 J)", .energy, .metric, d("4.184"))
    static let kilocalorie = UnitDefinition("food Calorie (kcal)", .energy, .metric, 4184)
    static let wattHour = UnitDefinition("Wh", .energy, .metric, 3600)
    static let kilowattHour = UnitDefinition("kWh", .energy, .metric, 3_600_000)
    static let btu = UnitDefinition("BTU", .energy, .customary, d("1055.05585262"))

    // Pressure, in pascals.
    static let pascal = UnitDefinition("Pa", .pressure, .metric, 1)
    static let hectopascal = UnitDefinition("hPa", .pressure, .metric, 100)
    static let kilopascal = UnitDefinition("kPa", .pressure, .metric, 1000)
    static let megapascal = UnitDefinition("MPa", .pressure, .metric, 1_000_000)
    static let bar = UnitDefinition("bar", .pressure, .metric, 100_000)
    static let millibar = UnitDefinition("mbar", .pressure, .metric, 100)
    static let atmosphere = UnitDefinition("atm", .pressure, .metric, 101_325)
    static let psi = UnitDefinition("psi", .pressure, .customary, d("6894.757293168"))
    static let mmHg = UnitDefinition("mmHg", .pressure, .metric, d("133.322387415"))
    static let inHg = UnitDefinition("inHg", .pressure, .customary, d("3386.389"))

    // Power, in watts.
    static let watt = UnitDefinition("W", .power, .metric, 1)
    static let kilowatt = UnitDefinition("kW", .power, .metric, 1000)
    static let megawatt = UnitDefinition("MW", .power, .metric, 1_000_000)
    static let horsepower = UnitDefinition("mechanical horsepower", .power, .customary, d("745.69987158227022"))
    static let metricHorsepower = UnitDefinition("metric horsepower (PS)", .power, .metric, d("735.49875"))
}
