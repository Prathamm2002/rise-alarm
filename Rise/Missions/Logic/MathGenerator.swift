//
//  MathGenerator.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

enum MathOp: String, Sendable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
}

struct MathProblem: Equatable, Sendable {
    let operands: [Int]
    let ops: [MathOp]
    let text: String
    let answer: Int
}

enum MathGenerator {
    static func make<G: RandomNumberGenerator>(_ difficulty: Difficulty, using g: inout G) -> MathProblem {
        switch difficulty {
        case .easy:
            var a = Int.random(in: 2...20, using: &g)
            var b = Int.random(in: 2...20, using: &g)
            if Bool.random(using: &g) {
                return problem([a, b], [.add])
            }
            if a < b { swap(&a, &b) }
            return problem([a, b], [.subtract])
        case .medium:
            let a = Int.random(in: 3...12, using: &g)
            let b = Int.random(in: 3...12, using: &g)
            let c = Int.random(in: 1...50, using: &g)
            return problem([a, b, c], [.multiply, .add])
        case .hard:
            let a = Int.random(in: 11...25, using: &g)
            let b = Int.random(in: 3...9, using: &g)
            let c = Int.random(in: 6...15, using: &g)
            let d = Int.random(in: 2...9, using: &g)
            return problem([a, b, c, d], [.multiply, .add, .multiply])
        }
    }

    /// Evaluates left to right with × binding tighter than + and −.
    static func evaluate(operands: [Int], ops: [MathOp]) -> Int {
        guard let first = operands.first else { return 0 }
        precondition(ops.count == operands.count - 1, "ops must sit between operands")
        var total = 0
        var term = first
        var pendingSign = 1
        for (index, op) in ops.enumerated() {
            let next = operands[index + 1]
            switch op {
            case .multiply:
                term *= next
            case .add, .subtract:
                total += pendingSign * term
                pendingSign = op == .add ? 1 : -1
                term = next
            }
        }
        return total + pendingSign * term
    }

    /// Trims whitespace, parses an Int and compares with the answer.
    static func check(_ input: String, against problem: MathProblem) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed) else { return false }
        return value == problem.answer
    }

    private static func problem(_ operands: [Int], _ ops: [MathOp]) -> MathProblem {
        var text = "\(operands[0])"
        for (index, op) in ops.enumerated() {
            text += " \(op.rawValue) \(operands[index + 1])"
        }
        return MathProblem(operands: operands, ops: ops, text: text,
                           answer: evaluate(operands: operands, ops: ops))
    }
}
