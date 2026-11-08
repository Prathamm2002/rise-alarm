//
//  MathGeneratorTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class MathGeneratorTests: XCTestCase {
    func testGeneratedProblemsAreConsistentAndInRange() {
        for seed in 0..<500 {
            for difficulty in Difficulty.allCases {
                var rng = SplitMix64(seed: UInt64(seed))
                let p = MathGenerator.make(difficulty, using: &rng)
                XCTAssertEqual(p.answer, MathGenerator.evaluate(operands: p.operands, ops: p.ops), p.text)
                XCTAssertGreaterThanOrEqual(p.answer, 0, p.text)
                XCTAssertEqual(p.ops.count, p.operands.count - 1)
                for operand in p.operands {
                    XCTAssertTrue(p.text.contains(String(operand)), p.text)
                }
                switch difficulty {
                case .easy:
                    XCTAssertEqual(p.operands.count, 2)
                    XCTAssertTrue(p.operands.allSatisfy { (2...20).contains($0) }, p.text)
                    XCTAssertTrue(p.ops == [.add] || p.ops == [.subtract])
                    if p.ops == [.subtract] { XCTAssertGreaterThanOrEqual(p.operands[0], p.operands[1]) }
                case .medium:
                    XCTAssertEqual(p.ops, [.multiply, .add])
                    XCTAssertTrue((3...12).contains(p.operands[0]))
                    XCTAssertTrue((3...12).contains(p.operands[1]))
                    XCTAssertTrue((1...50).contains(p.operands[2]))
                case .hard:
                    XCTAssertEqual(p.ops.filter { $0 == .multiply }.count, 2)
                    XCTAssertEqual(p.ops, [.multiply, .add, .multiply])
                    XCTAssertTrue((11...25).contains(p.operands[0]))
                    XCTAssertTrue((3...9).contains(p.operands[1]))
                    XCTAssertTrue((6...15).contains(p.operands[2]))
                    XCTAssertTrue((2...9).contains(p.operands[3]))
                }
            }
        }
    }

    func testPrecedence() {
        XCTAssertEqual(MathGenerator.evaluate(operands: [3, 4, 5], ops: [.multiply, .add]), 17)
        XCTAssertEqual(MathGenerator.evaluate(operands: [5, 3, 4], ops: [.add, .multiply]), 17)
        XCTAssertEqual(MathGenerator.evaluate(operands: [20, 2, 3], ops: [.subtract, .multiply]), 14)
        XCTAssertEqual(MathGenerator.evaluate(operands: [12, 3, 7, 2], ops: [.multiply, .add, .multiply]), 50)
        XCTAssertEqual(MathGenerator.evaluate(operands: [9, 4], ops: [.subtract]), 5)
    }

    func testCheckTrimsWhitespace() {
        let p = MathProblem(operands: [3, 4, 5], ops: [.multiply, .add], text: "3 × 4 + 5", answer: 17)
        XCTAssertTrue(MathGenerator.check(" 17 ", against: p))
        XCTAssertTrue(MathGenerator.check("17\n", against: p))
        XCTAssertFalse(MathGenerator.check("18", against: p))
        XCTAssertFalse(MathGenerator.check("", against: p))
        XCTAssertFalse(MathGenerator.check("abc", against: p))
    }
}
