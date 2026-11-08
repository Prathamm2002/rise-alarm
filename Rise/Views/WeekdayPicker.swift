//
//  WeekdayPicker.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

/// Seven circular day chips plus Weekdays / Weekends / Every day presets.
struct WeekdayPicker: View {
    @Binding var selection: Set<Weekday>

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(Weekday.displayOrder) { day in
                    let isOn = selection.contains(day)
                    Button {
                        if isOn { selection.remove(day) } else { selection.insert(day) }
                    } label: {
                        Text(day.initial)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 38, height: 38)
                            .foregroundStyle(isOn ? .white : Theme.secondaryText)
                            .background(Circle().fill(isOn ? Theme.accent : Theme.cardRaised))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(day.shortName)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                preset("Weekdays", Weekday.workdays)
                preset("Weekends", Weekday.weekend)
                preset("Every day", Weekday.everyDay)
            }
            Text(selection.isEmpty ? "Rings once" : "Repeats: \(summary)")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var summary: String {
        RiseAlarm(hour: 0, minute: 0, weekdays: selection).repeatSummary
    }

    private func preset(_ title: String, _ days: Set<Weekday>) -> some View {
        let isOn = selection == days
        return Button(title) {
            selection = isOn ? [] : days
        }
        .font(.footnote.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(isOn ? Theme.accent : .white)
        .background(Capsule().fill(isOn ? Theme.accentSoft : Theme.cardRaised))
        .buttonStyle(.plain)
    }
}
