//
//  NagChainTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class NagChainTests: XCTestCase {
    private let occurrence = Date(timeIntervalSince1970: 1_800_000_000)

    func testTenDatesOneMinuteApart() {
        let dates = NagChain.dates(occurrence: occurrence, policy: .standard)
        XCTAssertEqual(dates.count, 10)
        XCTAssertEqual(dates.map { $0.timeIntervalSince(occurrence) }, (1...10).map { Double($0) * 60 })
    }

    func testFutureDatesFilters() {
        let now = occurrence.addingTimeInterval(4 * 60 + 30)
        let future = NagChain.futureDates(occurrence: occurrence, now: now, policy: .standard)
        XCTAssertEqual(future.count, 6)
        XCTAssertTrue(future.allSatisfy { $0 > now })
        XCTAssertEqual(future.first, occurrence.addingTimeInterval(5 * 60))
    }

    func testFutureDatesExcludesExactNow() {
        let now = occurrence.addingTimeInterval(60)
        XCTAssertEqual(NagChain.futureDates(occurrence: occurrence, now: now, policy: .standard).count, 9)
    }

    func testWindow() {
        XCTAssertEqual(NagPolicy.standard.window, 1800)
        XCTAssertEqual(NagPolicy(count: 0).window, 1200)
        XCTAssertTrue(NagChain.dates(occurrence: occurrence, policy: NagPolicy(count: 0)).isEmpty)
    }
}
