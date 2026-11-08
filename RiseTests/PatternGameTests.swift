//
//  PatternGameTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class PatternGameTests: XCTestCase {
    func testSequenceLengthRangeAndNoConsecutiveRepeats() {
        for seed in 0..<300 {
            for length in 3...8 {
                var rng = SplitMix64(seed: UInt64(seed))
                let game = PatternGame(length: length, using: &rng)
                XCTAssertEqual(game.sequence.count, length)
                XCTAssertTrue(game.sequence.allSatisfy { (0..<9).contains($0) })
                for i in 1..<game.sequence.count {
                    XCTAssertNotEqual(game.sequence[i], game.sequence[i - 1])
                }
            }
        }
    }

    func testCorrectSequenceCompletes() {
        var rng = SplitMix64(seed: 42)
        var game = PatternGame(length: 5, using: &rng)
        let sequence = game.sequence
        for (index, tile) in sequence.enumerated() {
            let result = game.tap(tile)
            if index == sequence.count - 1 {
                XCTAssertEqual(result, .completed)
            } else {
                XCTAssertEqual(result, .correct)
                XCTAssertEqual(game.progress, index + 1)
            }
        }
        XCTAssertTrue(game.isCompleted)
    }

    func testWrongTapResetsProgress() {
        var rng = SplitMix64(seed: 7)
        var game = PatternGame(length: 5, using: &rng)
        XCTAssertEqual(game.tap(game.sequence[0]), .correct)
        XCTAssertEqual(game.tap(game.sequence[1]), .correct)
        let wrong = (game.sequence[2] + 1) % game.tileCount
        XCTAssertEqual(game.tap(wrong), .wrong)
        XCTAssertEqual(game.progress, 0)
    }

    func testRegenerateResetsProgressAndKeepsLength() {
        var rng = SplitMix64(seed: 9)
        var game = PatternGame(length: 6, using: &rng)
        _ = game.tap(game.sequence[0])
        game.regenerate(using: &rng)
        XCTAssertEqual(game.progress, 0)
        XCTAssertEqual(game.sequence.count, 6)
    }

    func testSameSeedIsDeterministic() {
        var a = SplitMix64(seed: 1234)
        var b = SplitMix64(seed: 1234)
        XCTAssertEqual(PatternGame(length: 8, using: &a).sequence, PatternGame(length: 8, using: &b).sequence)
    }
}
