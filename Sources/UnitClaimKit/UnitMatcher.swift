/// Matches a unit alias right after a number: attached (`5km`), after one space (`5 km`) or after a
/// hyphen (`a 10-mile hike`).
struct UnitMatcher {
    struct Match {
        let alias: UnitAlias
        let text: String
        let end: Int
        let isAttached: Bool
        let isHyphenated: Bool
    }

    let characters: [Character]

    func match(after end: Int, wordsOnly: Bool = false) -> Match? {
        guard end < characters.count else { return nil }
        let gap = characters[end]
        let start = gap == " " || gap == "-" ? end + 1 : end
        guard start < characters.count, characters[start] != " " else { return nil }
        for alias in UnitCatalog.aliases where !wordsOnly || alias.isWord {
            guard let stop = matchEnd(alias, at: start), isBoundary(after: stop, for: alias) else { continue }
            if gap == "-", start != end, alias.caseSensitive { continue }
            return Match(
                alias: alias, text: String(characters[start..<stop]), end: stop,
                isAttached: start == end, isHyphenated: gap == "-" && start != end
            )
        }
        return nil
    }

    /// Where the alias ends in the text when it is written at `start`; a space in an alias matches
    /// any run of spaces.
    private func matchEnd(_ alias: UnitAlias, at start: Int) -> Int? {
        var index = start
        for expected in alias.text {
            guard index < characters.count else { return nil }
            if expected == " " {
                guard characters[index] == " " else { return nil }
                while index < characters.count, characters[index] == " " { index += 1 }
                continue
            }
            guard same(characters[index], expected, exact: alias.caseSensitive) else { return nil }
            index += 1
        }
        return index
    }

    private func same(_ written: Character, _ expected: Character, exact: Bool) -> Bool {
        let normalized: Character = "º˚".contains(written) ? "°" : written
        return exact ? normalized == expected : normalized.lowercased() == expected.lowercased()
    }

    /// The unit ends a word, and for "in", punctuation follows.
    private func isBoundary(after stop: Int, for alias: UnitAlias) -> Bool {
        guard stop < characters.count else { return true }
        let next = characters[stop]
        if next.isLetter || NumberParser.isDigit(next) { return false }
        guard alias.needsPunctuationAfter else { return true }
        let rest = characters[stop...].drop { $0 == " " }
        return rest.first.map { "()=≈~/,;:".contains($0) } ?? true
    }
}
