//
//  NagChain.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// How many backup ("nag") alarms follow an occurrence, and how long the
/// mission stays pending afterwards.
struct NagPolicy: Sendable, Equatable {
    var count = 10
    var interval: TimeInterval = 60
    var grace: TimeInterval = 20 * 60

    /// Time after the occurrence during which the mission is still pending.
    var window: TimeInterval { Double(count) * interval + grace }

    static let standard = NagPolicy()
}

enum NagChain {
    /// `occurrence + k * interval` for k = 1...count.
    static func dates(occurrence: Date, policy: NagPolicy) -> [Date] {
        guard policy.count > 0 else { return [] }
        return (1...policy.count).map { occurrence.addingTimeInterval(Double($0) * policy.interval) }
    }

    /// Nag dates still in the future.
    static func futureDates(occurrence: Date, now: Date, policy: NagPolicy) -> [Date] {
        dates(occurrence: occurrence, policy: policy).filter { $0 > now }
    }
}

enum OccurrenceResolver {
    /// The unfinished occurrence that is "live" right now, or nil.
    ///
    /// Valid iff the previous fire date is after `armedSince`, after the last
    /// completed occurrence, and `now` is still inside the policy window.
    static func activeOccurrence(hour: Int, minute: Int, weekdays: Set<Weekday>, armedSince: Date,
                                 lastCompleted: Date?, now: Date, calendar: Calendar,
                                 policy: NagPolicy) -> Date? {
        guard let prev = NextFireCalculator.previousFireDate(hour: hour, minute: minute, weekdays: weekdays,
                                                             onOrBefore: now, calendar: calendar) else { return nil }
        guard prev > armedSince else { return nil }
        if let lastCompleted, prev <= lastCompleted { return nil }
        guard now < prev.addingTimeInterval(policy.window) else { return nil }
        return prev
    }

    /// The occurrence nags should be scheduled for: the active one, or else the next one.
    static func nagTargetOccurrence(hour: Int, minute: Int, weekdays: Set<Weekday>, armedSince: Date,
                                    lastCompleted: Date?, now: Date, calendar: Calendar,
                                    policy: NagPolicy) -> Date? {
        activeOccurrence(hour: hour, minute: minute, weekdays: weekdays, armedSince: armedSince,
                         lastCompleted: lastCompleted, now: now, calendar: calendar, policy: policy)
            ?? NextFireCalculator.nextFireDate(hour: hour, minute: minute, weekdays: weekdays,
                                               after: now, calendar: calendar)
    }

    /// Occurrences that should have nags pre-scheduled, most urgent first: the
    /// nag target and, for a repeating alarm, the occurrence after it.
    ///
    /// Keeping the following occurrence covered means a repeating alarm never
    /// wakes the user without backups, even if the app did not run (no intent,
    /// no launch) since the previous occurrence.
    static func nagTargetOccurrences(hour: Int, minute: Int, weekdays: Set<Weekday>, armedSince: Date,
                                     lastCompleted: Date?, now: Date, calendar: Calendar,
                                     policy: NagPolicy) -> [Date] {
        guard let primary = nagTargetOccurrence(hour: hour, minute: minute, weekdays: weekdays,
                                                armedSince: armedSince, lastCompleted: lastCompleted,
                                                now: now, calendar: calendar, policy: policy) else { return [] }
        guard !weekdays.isEmpty,
              let following = NextFireCalculator.nextFireDate(hour: hour, minute: minute, weekdays: weekdays,
                                                              after: primary, calendar: calendar) else {
            return [primary]
        }
        return [primary, following]
    }
}

extension RiseAlarm {
    func activeOccurrence(now: Date = .now, calendar: Calendar = .current,
                          policy: NagPolicy = .standard) -> Date? {
        OccurrenceResolver.activeOccurrence(hour: hour, minute: minute, weekdays: weekdays,
                                            armedSince: armedSince, lastCompleted: lastCompletedOccurrence,
                                            now: now, calendar: calendar, policy: policy)
    }

    func nagTargetOccurrence(now: Date = .now, calendar: Calendar = .current,
                             policy: NagPolicy = .standard) -> Date? {
        OccurrenceResolver.nagTargetOccurrence(hour: hour, minute: minute, weekdays: weekdays,
                                               armedSince: armedSince, lastCompleted: lastCompletedOccurrence,
                                               now: now, calendar: calendar, policy: policy)
    }

    func nagTargetOccurrences(now: Date = .now, calendar: Calendar = .current,
                              policy: NagPolicy = .standard) -> [Date] {
        OccurrenceResolver.nagTargetOccurrences(hour: hour, minute: minute, weekdays: weekdays,
                                                armedSince: armedSince, lastCompleted: lastCompletedOccurrence,
                                                now: now, calendar: calendar, policy: policy)
    }

    func nextFireDate(after date: Date = .now, calendar: Calendar = .current) -> Date? {
        NextFireCalculator.nextFireDate(hour: hour, minute: minute, weekdays: weekdays,
                                        after: date, calendar: calendar)
    }

    func previousFireDate(onOrBefore date: Date = .now, calendar: Calendar = .current) -> Date? {
        NextFireCalculator.previousFireDate(hour: hour, minute: minute, weekdays: weekdays,
                                            onOrBefore: date, calendar: calendar)
    }
}
