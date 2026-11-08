//
//  AlarmRowView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct AlarmRowView: View {
    let alarm: RiseAlarm
    let onToggle: (Bool) -> Void

    private var timeText: (time: String, period: String?) {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        let date = Calendar.current.date(from: components) ?? .now
        let formatted = date.formatted(.dateTime.hour().minute())
        // Split "7:05 AM" into time + period so the period can be smaller.
        let parts = formatted.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2, parts[1].rangeOfCharacter(from: .decimalDigits) == nil {
            return (parts[0], parts[1])
        }
        return (formatted, nil)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(timeText.time)
                        .font(Theme.timeFont(52))
                        .monospacedDigit()
                    if let period = timeText.period {
                        Text(period)
                            .font(.title3.weight(.light))
                    }
                }
                .foregroundStyle(alarm.isEnabled ? .white : Theme.secondaryText)
                HStack(spacing: 6) {
                    Image(systemName: alarm.mission.type.symbolName)
                        .foregroundStyle(alarm.isEnabled ? Theme.accent : Theme.secondaryText)
                    Text(subtitle)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: onToggle))
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        var parts: [String] = []
        if !alarm.label.isEmpty { parts.append(alarm.label) }
        parts.append(alarm.repeatSummary)
        parts.append(missionSummary)
        return parts.joined(separator: " · ")
    }

    private var missionSummary: String {
        let m = alarm.mission
        switch m.type {
        case .math: return "\(m.count) \(m.difficulty.rawValue) math"
        case .pattern: return "\(m.count)-tile memory"
        case .shake: return "\(m.count) shakes"
        case .phrase: return m.count == 1 ? "1 phrase" : "\(m.count) phrases"
        }
    }
}
