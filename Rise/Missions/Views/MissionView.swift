//
//  MissionView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

/// Full-screen mission. Cannot be dismissed except in practice mode.
struct MissionView: View {
    let mission: ActiveMission
    /// Called when the view should go away (after success, or on practice close).
    let onFinish: () -> Void

    @Environment(AppModel.self) private var model
    @State private var progress = 0
    @State private var finished = false

    private var target: Int { max(1, mission.config.count) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if finished {
                successView
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                content
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(true)
        .animation(.easeInOut(duration: 0.3), value: finished)
    }

    private var content: some View {
        VStack(spacing: 20) {
            header
            Group {
                switch mission.config.type {
                case .math:
                    MathMissionView(difficulty: mission.config.difficulty, target: target,
                                    progress: $progress, onComplete: complete)
                case .pattern:
                    PatternMissionView(length: target, onComplete: complete)
                case .shake:
                    ShakeMissionView(target: target, isPractice: mission.isPractice, onComplete: complete)
                case .phrase:
                    PhraseMissionView(target: target, progress: $progress, onComplete: complete)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Label(mission.isPractice ? "Practice" : mission.config.type.title,
                      systemImage: mission.config.type.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                if mission.isPractice {
                    Button {
                        onFinish()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .accessibilityLabel("Close practice")
                }
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(Theme.timeFont(76))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            Text(mission.label)
                .font(.headline)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
            if mission.config.type == .math || mission.config.type == .phrase {
                VStack(spacing: 6) {
                    ProgressView(value: Double(progress), total: Double(target))
                        .tint(Theme.accent)
                    Text("\(progress) / \(target)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.top, 4)
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 84))
                .foregroundStyle(Theme.sunriseGradient)
                .symbolEffect(.bounce, value: finished)
            Text(mission.isPractice ? "Nice work" : "Good morning")
                .font(.largeTitle.weight(.semibold))
            Text(mission.isPractice ? "That is how your mission will feel." : "Mission complete. Alarm is off.")
                .foregroundStyle(Theme.secondaryText)
        }
        .padding()
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        if !mission.isPractice {
            model.completeMission()
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            onFinish()
        }
    }
}
