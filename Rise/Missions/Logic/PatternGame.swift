//
//  PatternGame.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

enum PatternTapResult: Equatable, Sendable {
    case correct, wrong, completed
}

/// Memory game: repeat a sequence of tile taps. No tile appears twice in a row.
struct PatternGame: Sendable {
    let tileCount: Int
    let length: Int
    private(set) var sequence: [Int]
    private(set) var progress: Int = 0

    init<G: RandomNumberGenerator>(length: Int, tileCount: Int = 9, using g: inout G) {
        self.tileCount = max(2, tileCount)
        self.length = max(1, length)
        self.sequence = PatternGame.makeSequence(length: self.length, tileCount: self.tileCount, using: &g)
    }

    var isCompleted: Bool { progress >= sequence.count }

    mutating func tap(_ tile: Int) -> PatternTapResult {
        guard !isCompleted else { return .completed }
        if tile == sequence[progress] {
            progress += 1
            return isCompleted ? .completed : .correct
        }
        progress = 0
        return .wrong
    }

    /// New sequence of the same length; progress resets.
    mutating func regenerate<G: RandomNumberGenerator>(using g: inout G) {
        sequence = PatternGame.makeSequence(length: length, tileCount: tileCount, using: &g)
        progress = 0
    }

    private static func makeSequence<G: RandomNumberGenerator>(length: Int, tileCount: Int,
                                                              using g: inout G) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let last = result.last {
                // Pick among the other tileCount - 1 tiles, skipping `last`.
                var pick = Int.random(in: 0..<(tileCount - 1), using: &g)
                if pick >= last { pick += 1 }
                result.append(pick)
            } else {
                result.append(Int.random(in: 0..<tileCount, using: &g))
            }
        }
        return result
    }
}
