//
//  PhraseMatcherTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class PhraseMatcherTests: XCTestCase {
    private let target = "I am awake and ready to win today."

    func testExactMatch() {
        XCTAssertTrue(PhraseBank.matches(input: target, target: target))
    }

    func testTrailingWhitespaceIsIgnored() {
        XCTAssertTrue(PhraseBank.matches(input: target + " ", target: target))
        XCTAssertTrue(PhraseBank.matches(input: target + "\n", target: target))
        XCTAssertTrue(PhraseBank.matches(input: "  " + target, target: target))
    }

    func testMismatches() {
        XCTAssertFalse(PhraseBank.matches(input: target.lowercased(), target: target))
        XCTAssertFalse(PhraseBank.matches(input: String(target.dropLast()), target: target))
        XCTAssertFalse(PhraseBank.matches(input: "I am  awake and ready to win today.", target: target))
        XCTAssertFalse(PhraseBank.matches(input: "", target: target))
    }

    func testPhraseBankIsAsciiSafe() throws {
        XCTAssertGreaterThanOrEqual(PhraseBank.phrases.count, 20)
        let regex = try NSRegularExpression(pattern: "^[A-Za-z ,.!]+$")
        for phrase in PhraseBank.phrases {
            let range = NSRange(phrase.startIndex..., in: phrase)
            XCTAssertNotNil(regex.firstMatch(in: phrase, range: range), phrase)
            XCTAssertTrue(PhraseBank.matches(input: phrase, target: phrase))
        }
    }

    func testRandomReturnsBankPhrase() {
        var rng = SplitMix64(seed: 3)
        XCTAssertTrue(PhraseBank.phrases.contains(PhraseBank.random(using: &rng)))
    }
}
