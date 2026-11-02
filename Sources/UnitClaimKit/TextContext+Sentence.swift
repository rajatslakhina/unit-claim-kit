extension TextContext {
    /// The sentence holding `range`: from the last stop, `!`, `?` or line break before it to the next one.
    func sentence(around range: Range<Int>) -> Range<Int> {
        var start = range.lowerBound
        while start > 0, !endsSentence(at: start - 1) { start -= 1 }
        var end = range.upperBound
        while end < characters.count, !endsSentence(at: end) { end += 1 }
        return start..<end
    }

    private func endsSentence(at index: Int) -> Bool {
        let character = characters[index]
        if "\n!?".contains(character) { return true }
        return character == "." && (index + 1 == characters.count || characters[index + 1].isWhitespace)
    }

    /// A change word among the four words before the claim or the three after it.
    func marksChange(_ claim: Range<Int>, in sentence: Range<Int>) -> Bool {
        let before = words(in: sentence.lowerBound..<claim.lowerBound).suffix(4)
        let after = words(in: claim.upperBound..<sentence.upperBound).prefix(3)
        return (before + after).contains { Self.changeWords.contains($0) }
    }

    private func words(in range: Range<Int>) -> [String] {
        String(characters[range]).lowercased().split { !$0.isLetter }.map(String.init)
    }

    /// What a volume-to-mass claim measures. Words between the quantity and its link name it ("2 cups
    /// of stock (480 g)"), and then nothing else may stand in for it; otherwise the nearest substance
    /// within three words of the claim ("1 cup (120 g) flour", "Flour: 1 cup (120 g)").
    func substance(named subject: String, near claim: Range<Int>, in sentence: Range<Int>) -> Substance? {
        guard subject.isEmpty else {
            let words = Array(subject)
            return densities.names.first { !occurrences(of: $0.name, in: words, within: 0..<words.count).isEmpty }?
                .substance
        }
        let window = wordStart(before: claim.lowerBound, in: sentence)..<wordEnd(after: claim.upperBound, in: sentence)
        var best: (distance: Int, substance: Substance)?
        for entry in densities.names {
            for start in occurrences(of: entry.name, in: characters, within: window) {
                let end = start + entry.name.count
                let distance = end <= claim.lowerBound ? claim.lowerBound - end : max(0, start - claim.upperBound)
                if best.map({ distance < $0.distance }) ?? true { best = (distance, entry.substance) }
            }
        }
        return best?.substance
    }

    /// Where the third word before `index` starts, within the sentence.
    private func wordStart(before index: Int, in sentence: Range<Int>) -> Int {
        var start = index
        var words = 0
        while start > sentence.lowerBound, words < 3 {
            start -= 1
            if characters[start].isLetter, start == sentence.lowerBound || !characters[start - 1].isLetter {
                words += 1
            }
        }
        return start
    }

    /// Where the third word after `index` ends, within the sentence.
    private func wordEnd(after index: Int, in sentence: Range<Int>) -> Int {
        var end = index
        var words = 0
        while end < sentence.upperBound, words < 3 {
            if characters[end].isLetter, end + 1 == sentence.upperBound || !characters[end + 1].isLetter {
                words += 1
            }
            end += 1
        }
        return end
    }

    private func occurrences(of name: [Character], in text: [Character], within range: Range<Int>) -> [Int] {
        guard range.count >= name.count else { return [] }
        return (range.lowerBound...(range.upperBound - name.count)).filter { start in
            zip(text[start..<start + name.count], name).allSatisfy { $0.lowercased() == String($1) }
                && (start == range.lowerBound || !text[start - 1].isLetter)
                && (start + name.count == range.upperBound || !text[start + name.count].isLetter)
        }
    }
}
