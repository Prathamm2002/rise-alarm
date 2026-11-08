//
//  AlarmEditorView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct AlarmEditorView: View {
    /// nil means a new alarm.
    let original: RiseAlarm?

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var weekdays: Set<Weekday>
    @State private var label: String
    @State private var mission: MissionConfig
    @State private var practice: ActiveMission?
    @State private var confirmDelete = false

    init(alarm: RiseAlarm?) {
        original = alarm
        let base = alarm ?? RiseAlarm(hour: 7, minute: 0)
        var components = DateComponents()
        components.hour = base.hour
        components.minute = base.minute
        _time = State(initialValue: Calendar.current.date(from: components) ?? .now)
        _weekdays = State(initialValue: base.weekdays)
        _label = State(initialValue: base.label)
        _mission = State(initialValue: base.mission)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .riseCard()

                    section("Repeat") {
                        WeekdayPicker(selection: $weekdays)
                    }

                    section("Label") {
                        TextField("Wake up", text: $label)
                            .textInputAutocapitalization(.sentences)
                            .padding(12)
                            .background(Theme.cardRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    section("Mission") {
                        missionPicker
                        missionOptions
                        Button {
                            practice = model.practiceMission(mission, label: label)
                        } label: {
                            Label("Try mission", systemImage: "play.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                    }

                    if original != nil {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text("Delete alarm")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .foregroundStyle(Theme.danger)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(original == nil ? "New alarm" : "Edit alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete this alarm?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: delete)
            }
            .fullScreenCover(item: $practice) { mission in
                MissionView(mission: mission) { practice = nil }
                    .environment(model)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .riseCard()
    }

    private var missionPicker: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(MissionType.allCases) { type in
                let isOn = mission.type == type
                Button {
                    guard mission.type != type else { return }
                    var next = MissionConfig.default(for: type)
                    next.difficulty = mission.difficulty
                    mission = next
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: type.symbolName)
                            .font(.title2)
                        Text(type.title)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 78)
                    .foregroundStyle(isOn ? .white : Theme.secondaryText)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isOn ? Theme.accentSoft : Theme.cardRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isOn ? Theme.accent : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: mission.type)
    }

    @ViewBuilder
    private var missionOptions: some View {
        if mission.type == .math {
            Picker("Difficulty", selection: $mission.difficulty) {
                ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        Stepper(value: $mission.count,
                in: MissionConfig.countRange(for: mission.type),
                step: MissionConfig.countStep(for: mission.type)) {
            HStack {
                Text(countTitle)
                Spacer()
                Text("\(mission.count)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var countTitle: String {
        switch mission.type {
        case .math: "Problems"
        case .pattern: "Pattern length"
        case .shake: "Shakes"
        case .phrase: "Phrases"
        }
    }

    // MARK: Actions

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        var alarm = original ?? RiseAlarm(hour: 7, minute: 0)
        alarm.hour = components.hour ?? 7
        alarm.minute = components.minute ?? 0
        alarm.weekdays = weekdays
        alarm.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        alarm.mission = mission.normalized()
        alarm.isEnabled = true
        alarm.lastCompletedOccurrence = nil
        let toSave = alarm
        Task { await model.save(toSave) }
        dismiss()
    }

    private func delete() {
        guard let id = original?.id else { return }
        Task { await model.delete(id: id) }
        dismiss()
    }
}
