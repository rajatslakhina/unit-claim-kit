/// The words between two quantities that make the second a conversion of the first: `(`, `=`,
/// `is about`, `, or roughly`, `≈`.
struct Link: Sendable, Hashable {
    /// The second quantity sits in parentheses after the first.
    let isParenthetical: Bool
    /// Marked as approximate (`about`, `~`, `≈`).
    let isApproximate: Bool
    /// A bare `or` or `/`, which also joins alternatives ("2 cups or 3 tbsp").
    let isWeak: Bool
    /// Words before the link that name what is measured: "of flour" in "2 cups of flour (500 g)".
    var subject = ""

    private static let connectors = [
        "=", "==", "→", "->", "=>", "/", "is", "is exactly", "equals", "is equal to", "is equivalent to",
        "is the same as", "converts to", "works out to", "comes to", "comes out to", "or", "which is",
        "that is", "that's", "i.e.", "i.e.,", "≈", "~", "~=", "≅", "weighs", "weigh", "holds", "measures"
    ]
    private static let parentheticalConnectors = ["", "or", "=", "i.e.", "i.e.,", "that's", "that is", "≈", "~"]
    private static let separators = ["/", ",", "or", ", or", ";", "|"]
    private static let markers = [
        "about", "roughly", "approximately", "approx.", "approx", "around", "nearly", "almost", "close to",
        "just over", "just under", "some", "~", "≈"
    ]
    private static let approximateSymbols: Set = ["≈", "~", "~=", "≅"]

    /// Every accepted link, normalized, with what it marks.
    private static let between: [String: Link] = {
        var table: [String: Link] = [:]
        for connector in connectors {
            for marker in [""] + markers {
                let link = Link(isParenthetical: false, isApproximate: approximate(connector, marker),
                                isWeak: (connector == "or" || connector == "/") && marker.isEmpty)
                table[join(connector, marker)] = link
                table[join(",", connector, marker)] = Link(
                    isParenthetical: false, isApproximate: link.isApproximate, isWeak: false
                )
            }
        }
        for marker in markers {
            table[join(",", marker)] = Link(isParenthetical: false, isApproximate: true, isWeak: false)
        }
        for connector in parentheticalConnectors {
            for marker in [""] + markers {
                table[join("(", connector, marker)] = Link(
                    isParenthetical: true, isApproximate: approximate(connector, marker), isWeak: false
                )
            }
        }
        return table
    }()

    /// Further targets inside the same parentheses: `(3.1 mi / 5,000 m)`.
    private static let within: [String: Link] = {
        var table: [String: Link] = [:]
        for separator in separators {
            for marker in [""] + markers {
                table[join(separator, marker)] = Link(
                    isParenthetical: true, isApproximate: approximate(separator, marker), isWeak: false
                )
            }
        }
        return table
    }()

    /// The link between two quantities. Up to four words naming what is measured may come first
    /// ("2 cups of flour (500 g)", "a 1 TB drive is 931 GB"), but then not a bare "or" or "/".
    static func between(_ text: String) -> Link? {
        let normalized = normalize(text)
        if let link = between[normalized] { return link }
        let parts = normalized.split(separator: " ").map(String.init)
        for count in 1..<min(5, max(1, parts.count)) {
            guard parts[count - 1].allSatisfy({ $0.isLetter || "-'".contains($0) }) else { return nil }
            guard var link = between[parts.dropFirst(count).joined(separator: " ")], !link.isWeak else { continue }
            link.subject = parts.prefix(count).joined(separator: " ")
            return link
        }
        return nil
    }

    static func within(_ text: String) -> Link? { within[normalize(text)] }

    private static func approximate(_ connector: String, _ marker: String) -> Bool {
        !marker.isEmpty || approximateSymbols.contains(connector)
    }

    private static func join(_ parts: String...) -> String {
        normalize(parts.joined(separator: " "))
    }

    /// Lowercase, one space between words, none after `(` or before `,`.
    static func normalize(_ text: String) -> String {
        let words = text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return words.replacingOccurrences(of: "( ", with: "(").replacingOccurrences(of: " ,", with: ",")
    }
}
