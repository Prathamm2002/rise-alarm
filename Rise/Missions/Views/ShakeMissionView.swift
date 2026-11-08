//
//  ShakeMissionView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct ShakeMissionView: View {
    let target: Int
    let isPractice: Bool
    let onComplete: () -> Void

    @State private var monitor = MotionShakeMonitor()

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(monitor.count) / Double(target))
    }

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Theme.card, lineWidth: 18)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.sunriseGradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: monitor.count)
                VStack(spacing: 4) {
                    Text("\(monitor.count)")
                        .font(Theme.timeFont(72))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("of \(target) shakes")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .frame(width: 240, height: 240)
            .padding(.top, 12)

            if monitor.isAvailable {
                Label("Shake your iPhone hard", systemImage: "iphone.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .symbolEffect(.wiggle, options: .repeating)
            } else {
                VStack(spacing: 12) {
                    Text("Motion sensors are not available on this device.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.secondaryText)
                    if isPractice {
                        Button("Simulate shake") { monitor.simulateShake() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: monitor.count)
        .onAppear {
            monitor.start(target: target) { onComplete() }
        }
        .onDisappear { monitor.stop() }
    }
}
