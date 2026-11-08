//
//  NextFireCalculatorTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class NextFireCalculatorTests: XCTestCase {
    private func calendar(_ zone: String = "Asia/Kolkata") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, cal: Calendar) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // 2026-11-06 is a Friday.

    func testOneTimeEarlierGoesToTomorrow() {
        let cal = calendar()
        let now = date(2026, 11, 6, 9, 0, cal: cal)
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 11, 7, 7, 0, cal: cal))
    }

    func testOneTimeLaterGoesToToday() {
        let cal = calendar()
        let now = date(2026, 11, 6, 6, 30, cal: cal)
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 11, 6, 7, 0, cal: cal))
    }

    func testEqualToNowGoesToTomorrow() {
        let cal = calendar()
        let now = date(2026, 11, 6, 7, 0, cal: cal)
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 11, 7, 7, 0, cal: cal))
    }

    func testWeekdaysOnlyWrapsToMonday() {
        let cal = calendar()
        let now = date(2026, 11, 6, 8, 0, cal: cal) // Friday 08:00
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: Weekday.workdays,
                                                   after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 11, 9, 7, 0, cal: cal)) // Monday
    }

    func testSingleWeekdayGoesToNextWeek() {
        let cal = calendar()
        let now = date(2026, 11, 6, 8, 0, cal: cal)
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: [.friday],
                                                   after: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 11, 13, 7, 0, cal: cal))
    }

    func testPreviousSameDay() {
        let cal = calendar()
        let now = date(2026, 11, 6, 7, 5, cal: cal)
        let prev = NextFireCalculator.previousFireDate(hour: 7, minute: 0, weekdays: [], onOrBefore: now, calendar: cal)
        XCTAssertEqual(prev, date(2026, 11, 6, 7, 0, cal: cal))
    }

    func testPreviousIncludesExactTime() {
        let cal = calendar()
        let now = date(2026, 11, 6, 7, 0, cal: cal)
        let prev = NextFireCalculator.previousFireDate(hour: 7, minute: 0, weekdays: [], onOrBefore: now, calendar: cal)
        XCTAssertEqual(prev, now)
    }

    func testPreviousBeforeTimeGoesToYesterday() {
        let cal = calendar()
        let now = date(2026, 11, 6, 6, 0, cal: cal)
        let prev = NextFireCalculator.previousFireDate(hour: 7, minute: 0, weekdays: [], onOrBefore: now, calendar: cal)
        XCTAssertEqual(prev, date(2026, 11, 5, 7, 0, cal: cal))
    }

    func testPreviousWeekdaysOnlyOnMondayMorningGoesToFriday() {
        let cal = calendar()
        let now = date(2026, 11, 9, 6, 0, cal: cal) // Monday 06:00
        let prev = NextFireCalculator.previousFireDate(hour: 7, minute: 0, weekdays: Weekday.workdays,
                                                       onOrBefore: now, calendar: cal)
        XCTAssertEqual(prev, date(2026, 11, 6, 7, 0, cal: cal))
    }

    func testPreviousSingleWeekdayGoesToLastWeek() {
        let cal = calendar()
        let now = date(2026, 11, 13, 6, 0, cal: cal) // Friday before 07:00
        let prev = NextFireCalculator.previousFireDate(hour: 7, minute: 0, weekdays: [.friday],
                                                       onOrBefore: now, calendar: cal)
        XCTAssertEqual(prev, date(2026, 11, 6, 7, 0, cal: cal))
    }

    func testDSTSpringForwardKeepsWallClockTime() {
        let cal = calendar("America/New_York")
        // DST starts 2027-03-14 02:00 local.
        let now = date(2027, 3, 13, 9, 0, cal: cal)
        let next = NextFireCalculator.nextFireDate(hour: 7, minute: 0, weekdays: [], after: now, calendar: cal)!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: next)
        XCTAssertEqual(comps, DateComponents(year: 2027, month: 3, day: 14, hour: 7, minute: 0))
    }
}
