//
//  RiseAlarm.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Own weekday enum (Calendar numbering: Sunday = 1) so persistence never
/// depends on `Locale.Weekday`'s Codable representation.
enum Weekday: Int, Codable, CaseIterable, Sendable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }

    /// One-letter chip label.
    var initial: String { String(shortName.prefix(1)) }

    var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: .sunday
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        }
    }

    /// Monday-first display order.
    static var displayOrder: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }

    static var workdays: Set<Weekday> { [.monday, .tuesday, .wednesday, .thursday, .friday] }
    static var weekend: Set<Weekday> { [.saturday, .sunday] }
    static var everyDay: Set<Weekday> { Set(Weekday.allCases) }
}

enum MissionType: String, Codable, CaseIterable, Sendable, Identifiable {
    case math, pattern, shake, phrase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: "Math"
        case .pattern: "Memory"
        case .shake: "Shake"
        case .phrase: "Type phrase"
        }
    }

    var symbolName: String {
        switch self {
        case .math: "function"
        case .pattern: "square.grid.3x3"
        case .shake: "iphone.radiowaves.left.and.right"
        case .phrase: "keyboard"
        }
    }

    /// Unit word used for counts ("3 problems").
    var unitName: String {
        switch self {
        case .math: "problems"
        case .pattern: "tiles"
        case .shake: "shakes"
        case .phrase: "phrases"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Sendable, Identifiable {
    case easy, medium, hard

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct MissionConfig: Codable, Hashable, Sendable {
    var type: MissionType
    var difficulty: Difficulty
    var count: Int

    static func `default`(for type: MissionType) -> MissionConfig {
        switch type {
        case .math: MissionConfig(type: .math, difficulty: .medium, count: 3)
        case .pattern: MissionConfig(type: .pattern, difficulty: .medium, count: 5)
        case .shake: MissionConfig(type: .shake, difficulty: .medium, count: 30)
        case .phrase: MissionConfig(type: .phrase, difficulty: .medium, count: 1)
        }
    }

    static func countRange(for type: MissionType) -> ClosedRange<Int> {
        switch type {
        case .math: 1...10
        case .pattern: 3...8
        case .shake: 10...100
        case .phrase: 1...3
        }
    }

    static func countStep(for type: MissionType) -> Int {
        type == .shake ? 10 : 1
    }

    /// Clamps `count` into the valid range for `type`.
    func normalized() -> MissionConfig {
        var copy = self
        let range = MissionConfig.countRange(for: type)
        copy.count = min(max(count, range.lowerBound), range.upperBound)
        return copy
    }
}

struct RiseAlarm: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var hour: Int
    var minute: Int
    /// Empty means a one-time alarm.
    var weekdays: Set<Weekday>
    var label: String
    var isEnabled: Bool
    var mission: MissionConfig
    /// Set on create / edit / enable. Occurrences at or before this are never "pending".
    var armedSince: Date
    var lastCompletedOccurrence: Date?

    init(id: UUID = UUID(),
         hour: Int,
         minute: Int,
         weekdays: Set<Weekday> = [],
         label: String = "",
         isEnabled: Bool = true,
         mission: MissionConfig = .default(for: .math),
         armedSince: Date = .now,
         lastCompletedOccurrence: Date? = nil) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.label = label
        self.isEnabled = isEnabled
        self.mission = mission
        self.armedSince = armedSince
        self.lastCompletedOccurrence = lastCompletedOccurrence
    }

    var isRepeating: Bool { !weekdays.isEmpty }

    var displayLabel: String { label.isEmpty ? "Alarm" : label }

    var repeatSummary: String {
        if weekdays.isEmpty { return "Once" }
        if weekdays == Weekday.everyDay { return "Every day" }
        if weekdays == Weekday.workdays { return "Weekdays" }
        if weekdays == Weekday.weekend { return "Weekends" }
        return Weekday.displayOrder.filter { weekdays.contains($0) }.map(\.shortName).joined(separator: ", ")
    }

    /// "07:05" in 24h form; views format with the locale instead.
    var timeString: String { String(format: "%02d:%02d", hour, minute) }
}
