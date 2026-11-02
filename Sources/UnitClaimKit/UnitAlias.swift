/// A way a unit is written after a number, and the sizes it can mean.
struct UnitAlias: Sendable {
    /// The written form, with a single space wherever any run of spaces may appear.
    let text: [Character]
    /// Symbols (`MB` against `Mb`, `cal` against `Cal`) are matched exactly; words in any case.
    let caseSensitive: Bool
    /// The sizes it can mean, the usual one first.
    let sizes: [UnitDefinition]
    /// Read only when punctuation follows (`12 in (30 cm)`), so the word "in" is left alone.
    let needsPunctuationAfter: Bool
    /// A spelled-out unit that a number word can precede: "a mile", "two cups".
    var isWord: Bool { !caseSensitive && text.count > 2 && text.allSatisfy { $0.isLetter || $0 == " " } }
}

extension UnitCatalog {
    /// Every alias, longest first, so `km/h` is tried before `km` and `kilowatt hours` before `kilowatts`.
    static let aliases: [UnitAlias] = (symbols.flatMap { entry in
        entry.0.map { UnitAlias(text: Array($0), caseSensitive: true, sizes: entry.1, needsPunctuationAfter: false) }
    } + words.flatMap { entry in
        entry.0.map {
            UnitAlias(text: Array($0), caseSensitive: false, sizes: entry.1, needsPunctuationAfter: $0 == "in")
        }
    }).sorted { $0.text.count > $1.text.count }

    /// Written exactly as here.
    private static let symbols: [([String], [UnitDefinition])] = [
        (["m"], [metre]), (["µm", "μm"], [micrometre]),
        (["m²", "m2", "m^2"], [squareMetre]), (["km²", "km2", "km^2"], [squareKilometre]),
        (["cm²", "cm2", "cm^2"], [squareCentimetre]), (["ft²", "ft2", "ft^2"], [squareFoot]),
        (["in²", "in^2"], [squareInch]), (["yd²"], [squareYard]), (["mi²"], [squareMile]),
        (["mL", "ml"], [millilitre]), (["cl", "cL"], [centilitre]), (["dl", "dL"], [decilitre]),
        (["L"], [litre]), (["m³", "m3", "m^3"], [cubicMetre]), (["cm³", "cm3", "cc"], [cubicCentimetre]),
        (["in³"], [cubicInch]), (["ft³", "ft3"], [cubicFoot]),
        (["µg", "μg", "mcg"], [microgram]), (["mg"], [milligram]), (["g"], [gram]),
        (["°C", "° C", "C"], [celsius]), (["°F", "° F", "F"], [fahrenheit]),
        (["ms"], [millisecond]), (["s"], [second]), (["h"], [hour]),
        (["m/s"], [metrePerSecond]), (["km/h", "km/hr"], [kilometrePerHour]), (["ft/s"], [footPerSecond]),
        (["bit", "bits"], [bit]), (["Mb", "Mbit"], [megabit]), (["Gb", "Gbit"], [gigabit]), (["B"], [byte]),
        (["kB", "KB"], [kilobyte, kibibyte]), (["MB"], [megabyte, mebibyte]), (["GB"], [gigabyte, gibibyte]),
        (["TB"], [terabyte, tebibyte]), (["KiB"], [kibibyte]), (["MiB"], [mebibyte]), (["GiB"], [gibibyte]),
        (["TiB"], [tebibyte]),
        (["J"], [joule]), (["kJ", "KJ"], [kilojoule]), (["MJ"], [megajoule]), (["cal"], [calorie]),
        (["Cal"], [kilocalorie]), (["Wh"], [wattHour]), (["kWh"], [kilowattHour]),
        (["Pa"], [pascal]), (["hPa"], [hectopascal]), (["kPa"], [kilopascal]), (["MPa"], [megapascal]),
        (["mbar"], [millibar]), (["mmHg", "mm Hg"], [mmHg]), (["inHg", "in Hg"], [inHg]),
        (["W"], [watt]), (["kW"], [kilowatt]), (["MW"], [megawatt]), (["PS"], [metricHorsepower])
    ]

    /// Matched in any case.
    private static let words: [([String], [UnitDefinition])] = lengths + volumes + masses + others

    private static let lengths: [([String], [UnitDefinition])] = [
        (["meter", "meters", "metre", "metres"], [metre]),
        (["km", "kilometer", "kilometers", "kilometre", "kilometres"], [kilometre]),
        (["cm", "centimeter", "centimeters", "centimetre", "centimetres"], [centimetre]),
        (["mm", "millimeter", "millimeters", "millimetre", "millimetres"], [millimetre]),
        (["micron", "microns", "micrometer", "micrometers", "micrometre", "micrometres"], [micrometre]),
        (["in", "in.", "inch", "inches"], [inch]), (["ft", "foot", "feet"], [foot]),
        (["yd", "yds", "yard", "yards"], [yard]), (["mi", "mile", "miles", "statute mile", "statute miles"], [mile]),
        (["nmi", "nautical mile", "nautical miles"], [nauticalMile]),
        (["sq m", "sqm", "square meter", "square meters", "square metre", "square metres"], [squareMetre]),
        (["sq km", "square kilometer", "square kilometers", "square kilometre", "square kilometres"],
         [squareKilometre]),
        (["square centimeter", "square centimeters", "square centimetre", "square centimetres"], [squareCentimetre]),
        (["sq in", "square inch", "square inches"], [squareInch]),
        (["sq ft", "sq. ft.", "sq. ft", "sqft", "square foot", "square feet"], [squareFoot]),
        (["sq yd", "square yard", "square yards"], [squareYard]),
        (["sq mi", "square mile", "square miles"], [squareMile]),
        (["acre", "acres"], [acre]), (["ha", "hectare", "hectares"], [hectare])
    ]

    private static let volumes: [([String], [UnitDefinition])] = [
        (["milliliter", "milliliters", "millilitre", "millilitres"], [millilitre]),
        (["liter", "liters", "litre", "litres", "ltr"], [litre]),
        (["cubic meter", "cubic meters", "cubic metre", "cubic metres"], [cubicMetre]),
        (["cubic centimeter", "cubic centimeters", "cubic centimetre", "cubic centimetres"], [cubicCentimetre]),
        (["cu in", "cubic inch", "cubic inches"], [cubicInch]), (["cu ft", "cubic foot", "cubic feet"], [cubicFoot]),
        (["tsp", "teaspoon", "teaspoons"], [usTeaspoon, metricTeaspoon]),
        (["tbsp", "tbs", "tablespoon", "tablespoons"], [usTablespoon, metricTablespoon]),
        (["fl oz", "fl. oz.", "fl. oz", "fl.oz.", "floz", "fluid ounce", "fluid ounces"],
         [usFluidOunce, imperialFluidOunce]),
        (["us fl oz", "us fluid ounce", "us fluid ounces"], [usFluidOunce]),
        (["imperial fl oz", "uk fl oz", "imperial fluid ounce", "imperial fluid ounces"], [imperialFluidOunce]),
        (["cup", "cups"], [usCup, usLegalCup, metricCup, imperialCup]),
        (["us cup", "us cups"], [usCup, usLegalCup]), (["metric cup", "metric cups"], [metricCup]),
        (["pt", "pint", "pints"], [usPint, imperialPint]), (["us pint", "us pints"], [usPint]),
        (["imperial pint", "imperial pints", "uk pint", "uk pints"], [imperialPint]),
        (["qt", "quart", "quarts"], [usQuart, imperialQuart]), (["us quart", "us quarts"], [usQuart]),
        (["imperial quart", "imperial quarts"], [imperialQuart]),
        (["gal", "gallon", "gallons"], [usGallon, imperialGallon]), (["us gallon", "us gallons"], [usGallon]),
        (["imperial gallon", "imperial gallons", "uk gallon", "uk gallons"], [imperialGallon])
    ]

    private static let masses: [([String], [UnitDefinition])] = [
        (["microgram", "micrograms"], [microgram]), (["milligram", "milligrams"], [milligram]),
        (["gram", "grams", "gramme", "grammes"], [gram]),
        (["kg", "kgs", "kilo", "kilos", "kilogram", "kilograms"], [kilogram]),
        (["oz", "ounce", "ounces"], [ounce]), (["lb", "lbs", "pound", "pounds"], [pound]),
        (["stone"], [stone]), (["ton", "tons"], [shortTon, longTon, tonne]),
        (["short ton", "short tons", "us ton", "us tons"], [shortTon]),
        (["long ton", "long tons", "imperial ton", "imperial tons"], [longTon]),
        (["tonne", "tonnes", "metric ton", "metric tons"], [tonne])
    ]

    private static let others: [([String], [UnitDefinition])] = [
        (["degrees celsius", "degree celsius", "degrees centigrade", "celsius", "centigrade", "degrees c"],
         [celsius]),
        (["degrees fahrenheit", "degree fahrenheit", "fahrenheit", "degrees f"], [fahrenheit]),
        (["kelvin", "kelvins"], [kelvin]),
        (["millisecond", "milliseconds"], [millisecond]), (["sec", "secs", "second", "seconds"], [second]),
        (["min", "mins", "minute", "minutes"], [minute]), (["hr", "hrs", "hour", "hours"], [hour]),
        (["day", "days"], [day]), (["wk", "wks", "week", "weeks"], [week]),
        (["meters per second", "metres per second", "meter per second", "metre per second"], [metrePerSecond]),
        (["kph", "kmh", "kmph", "km per hour", "kilometers per hour", "kilometres per hour"], [kilometrePerHour]),
        (["mph", "mi/h", "miles per hour", "mile per hour"], [milePerHour]), (["knot", "knots"], [knot]),
        (["feet per second"], [footPerSecond]),
        (["megabit", "megabits"], [megabit]), (["gigabit", "gigabits"], [gigabit]), (["byte", "bytes"], [byte]),
        (["kilobyte", "kilobytes"], [kilobyte, kibibyte]), (["megabyte", "megabytes"], [megabyte, mebibyte]),
        (["gigabyte", "gigabytes"], [gigabyte, gibibyte]), (["terabyte", "terabytes"], [terabyte, tebibyte]),
        (["joule", "joules"], [joule]), (["kilojoule", "kilojoules"], [kilojoule]),
        (["kcal", "kilocalorie", "kilocalories"], [kilocalorie]), (["calorie", "calories"], [kilocalorie, calorie]),
        (["kilowatt hour", "kilowatt hours", "kilowatt-hour", "kilowatt-hours"], [kilowattHour]),
        (["btu", "btus"], [btu]), (["pascal", "pascals"], [pascal]), (["kilopascal", "kilopascals"], [kilopascal]),
        (["bar", "bars"], [bar]), (["millibar", "millibars"], [millibar]), (["psi"], [psi]),
        (["atm", "atmosphere", "atmospheres"], [atmosphere]),
        (["watt", "watts"], [watt]), (["kilowatt", "kilowatts"], [kilowatt]), (["megawatt", "megawatts"], [megawatt]),
        (["hp", "bhp", "horsepower"], [horsepower, metricHorsepower]), (["metric horsepower"], [metricHorsepower])
    ]
}
