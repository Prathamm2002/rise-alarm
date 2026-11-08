//
//  ShakeDetectorTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class ShakeDetectorTests: XCTestCase {
    func testRestingPhoneCountsNothing() {
        var detector = ShakeDetector()
        for i in 0..<200 {
            XCTAssertFalse(detector.process(x: 0, y: 0, z: -1, at: Double(i) / 50))
        }
        XCTAssertEqual(detector.count, 0)
    }

    func testSpacedSpikesCountEach() {
        var detector = ShakeDetector()
        XCTAssertTrue(detector.process(x: 2.5, y: 0, z: 0, at: 0))
        XCTAssertTrue(detector.process(x: 0, y: 2.5, z: 0, at: 0.35))
        XCTAssertTrue(detector.process(x: 0, y: 0, z: 2.5, at: 0.7))
        XCTAssertEqual(detector.count, 3)
    }

    func testRapidSpikesAreDebounced() {
        var detector = ShakeDetector()
        _ = detector.process(x: 2.5, y: 0, z: 0, at: 0)
        _ = detector.process(x: 2.5, y: 0, z: 0, at: 0.1)
        _ = detector.process(x: 2.5, y: 0, z: 0, at: 0.2)
        XCTAssertEqual(detector.count, 1)
    }
}
