//
//  NextFireCalculator.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Pure date maths for alarm occurrences. Empty `weekdays` means every day is a
/// candidate (the one-time alarm case).
enum NextFireCalculator {
    /// First occurrence strictly later than `after`.
    static func nextFireDate(hour: Int, minute: Int, weekdays: Set<Weekday>,
                             after: Date, calendar: Calendar) -> Date? {
        let startOfDay = calendar.startOfDay(for: after)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfDay),
                  let candidate = candidate(on: day, hour: hour, minute: minute,
                                            weekdays: weekdays, calendar: calendar) else { continue }
            if candidate > after { return candidate }
        }
        return nil
    }

    /// Latest occurrence at or before `onOrBefore`.
    static func previousFireDate(hour: Int, minute: Int, weekdays: Set<Weekday>,
                                 onOrBefore: Date, calendar: Calendar) -> Date? {
        let startOfDay = calendar.startOfDay(for: onOrBefore)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfDay),
                  let candidate = candidate(on: day, hour: hour, minute: minute,
                                            weekdays: weekdays, calendar: calendar) else { continue }
            if candidate <= onOrBefore { return candidate }
        }
        return nil
    }

    private static func candidate(on day: Date, hour: Int, minute: Int,
                                  weekdays: Set<Weekday>, calendar: Calendar) -> Date? {
        if !weekdays.isEmpty {
            let weekdayNumber = calendar.component(.weekday, from: day)
            guard let weekday = Weekday(rawValue: weekdayNumber), weekdays.contains(weekday) else { return nil }
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}
