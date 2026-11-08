//
//  OccurrenceResolverTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class OccurrenceResolverTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return c
    }

    private func date(_ d: Int, _ h: Int, _ m: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: h, minute: m))!
    }

    private func active(now: Date, armedSince: Date, lastCompleted: Date? = nil,
                        weekdays: Set<Weekday> = []) -> Date? {
        OccurrenceResolver.activeOccurrence(hour: 7, minute: 0, weekdays: weekdays, armedSince: armedSince,
                                            lastCompleted: lastCompleted, now: now, calendar: cal,
                                            policy: .standard)
    }

    func testActiveInsideWindow() {
        XCTAssertEqual(active(now: date(6, 7, 3), armedSince: date(5, 22, 0)), date(6, 7, 0))
        XCTAssertEqual(active(now: date(6, 7, 0), armedSince: date(5, 22, 0)), date(6, 7, 0))
        XCTAssertEqual(active(now: date(6, 7, 29), armedSince: date(5, 22, 0)), date(6, 7, 0))
    }

    func testNilAfterWindow() {
        XCTAssertNil(active(now: date(6, 7, 30), armedSince: date(5, 22, 0)))
        XCTAssertNil(active(now: date(6, 9, 0), armedSince: date(5, 22, 0)))
    }

    func testNilWhenCompleted() {
        XCTAssertNil(active(now: date(6, 7, 3), armedSince: date(5, 22, 0), lastCompleted: date(6, 7, 0)))
    }

    func testOlderCompletionDoesNotHideNewOccurrence() {
        XCTAssertEqual(active(now: date(6, 7, 3), armedSince: date(1, 22, 0), lastCompleted: date(5, 7, 0)),
                       date(6, 7, 0))
    }

    func testEditAfterAlarmTimeIsNotRetroactive() {
        // Edited at 07:05 for a 07:00 alarm: no pending mission.
        XCTAssertNil(active(now: date(6, 7, 6), armedSince: date(6, 7, 5)))
        XCTAssertNil(active(now: date(6, 7, 0), armedSince: date(6, 7, 0)))
    }

    func testRepeatingNonMatchingDayIsNil() {
        // Saturday 07:03, weekdays-only alarm: previous fire is Friday, far outside window.
        XCTAssertNil(active(now: date(7, 7, 3), armedSince: date(1, 0, 0), weekdays: Weekday.workdays))
    }

    func testNagTargetUsesActiveOccurrence() {
        let target = OccurrenceResolver.nagTargetOccurrence(hour: 7, minute: 0, weekdays: [],
                                                            armedSince: date(5, 22, 0), lastCompleted: nil,
                                                            now: date(6, 7, 3), calendar: cal, policy: .standard)
        XCTAssertEqual(target, date(6, 7, 0))
    }

    func testNagTargetFallsBackToNextFireDate() {
        let completed = OccurrenceResolver.nagTargetOccurrence(hour: 7, minute: 0, weekdays: [],
                                                               armedSince: date(5, 22, 0), lastCompleted: date(6, 7, 0),
                                                               now: date(6, 7, 3), calendar: cal, policy: .standard)
        XCTAssertEqual(completed, date(7, 7, 0))

        let beforeTime = OccurrenceResolver.nagTargetOccurrence(hour: 7, minute: 0, weekdays: [],
                                                                armedSince: date(5, 22, 0), lastCompleted: nil,
                                                                now: date(5, 23, 0), calendar: cal, policy: .standard)
        XCTAssertEqual(beforeTime, date(6, 7, 0))
    }
}
