//
//  AlarmListView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct AlarmListView: View {
    @Environment(AppModel.self) private var model

    private enum EditorTarget: Identifiable {
        case new
        case edit(RiseAlarm)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let alarm): alarm.id.uuidString
            }
        }

        var alarm: RiseAlarm? {
            if case .edit(let alarm) = self { return alarm }
            return nil
        }
    }

    @State private var editor: EditorTarget?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                    if !model.authorized && !AppEnvironment.isRunningTests {
                        PermissionBanner(authorization: model.authorization) {
                            Task { await model.requestAuthorization() }
                        }
                    }
                    if let error = model.lastError {
                        ErrorBanner(message: error) { model.scheduler.clearError() }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                if model.store.alarms.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(model.store.alarms) { alarm in
                            Button {
                                editor = .edit(alarm)
                            } label: {
                                AlarmRowView(alarm: alarm) { enabled in
                                    let id = alarm.id
                                    Task { await model.setEnabled(id: id, enabled) }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Theme.card)
                                    .padding(.vertical, 4)
                            )
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let id = alarm.id
                                    Task { await model.delete(id: id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Rise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editor = .new
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("Add alarm")
                }
            }
            .sheet(item: $editor) { target in
                AlarmEditorView(alarm: target.alarm)
                    .environment(model)
            }
            // A real mission always wins over the editor sheet.
            .onChange(of: model.router.active?.id) { _, newValue in
                if newValue != nil { editor = nil }
            }
        }
    }

    private var header: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(alignment: .leading, spacing: 6) {
                if let next = model.nextAlarmDate(after: context.date) {
                    Text("Next alarm in \(Self.countdown(from: context.date, to: next.date))")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(next.date.formatted(.dateTime.weekday(.wide).hour().minute())) · \(next.alarm.mission.type.title) mission")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("No alarms set")
                        .font(.title3.weight(.semibold))
                    Text("Add an alarm and pick a mission to turn it off.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.card)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Theme.sunriseGradient)
                            .opacity(0.35)
                            .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "alarm")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(Theme.accent)
            Text("No alarms yet")
                .font(.title3.weight(.semibold))
            Text("Rise only goes quiet once you finish a mission: math, memory, shake or typing.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
            Button {
                editor = .new
            } label: {
                Label("Add alarm", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    static func countdown(from now: Date, to date: Date) -> String {
        let minutes = max(1, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        let days = minutes / (24 * 60)
        let hours = (minutes % (24 * 60)) / 60
        let mins = minutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
