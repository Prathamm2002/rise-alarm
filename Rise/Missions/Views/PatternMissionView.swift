//
//  PatternMissionView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct PatternMissionView: View {
    let length: Int
    let onComplete: () -> Void

    private enum Phase: Equatable { case watch, input, wrong, done }

    @State private var game: PatternGame
    @State private var phase: Phase = .watch
    @State private var lit: Int?
    @State private var tapped: Int?
    @State private var playbackID = 0

    init(length: Int, onComplete: @escaping () -> Void) {
        self.length = length
        self.onComplete = onComplete
        var rng = SystemRandomNumberGenerator()
        self._game = State(initialValue: PatternGame(length: length, using: &rng))
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        VStack(spacing: 22) {
            Text(statusText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(phase == .wrong ? Theme.danger : .white)
                .contentTransition(.opacity)
            Text(phase == .input ? "\(game.progress) / \(game.sequence.count)" : "Remember \(game.sequence.count) tiles")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<game.tileCount, id: \.self) { tile in
                    tileView(tile)
                }
            }
            .padding(.top, 8)
            .allowsHitTesting(phase == .input)
        }
        .task(id: playbackID) { await playSequence() }
    }

    private var statusText: String {
        switch phase {
        case .watch: "Watch the pattern"
        case .input: "Your turn"
        case .wrong: "Wrong, watch again"
        case .done: "Perfect"
        }
    }

    private func tileView(_ tile: Int) -> some View {
        let isLit = lit == tile
        let isTapped = tapped == tile
        return Button {
            handleTap(tile)
        } label: {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isLit ? AnyShapeStyle(Theme.sunriseGradient)
                      : isTapped ? AnyShapeStyle(Theme.accent.opacity(0.55))
                      : AnyShapeStyle(Theme.card))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: isLit ? Theme.accent.opacity(0.6) : .clear, radius: 16)
                .scaleEffect(isLit || isTapped ? 1.04 : 1)
                .animation(.easeOut(duration: 0.15), value: isLit)
                .animation(.easeOut(duration: 0.1), value: isTapped)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tile \(tile + 1)")
    }

    private func playSequence() async {
        phase = playbackID == 0 ? .watch : phase
        lit = nil
        try? await Task.sleep(for: .milliseconds(phase == .wrong ? 1100 : 700))
        guard !Task.isCancelled else { return }
        phase = .watch
        for tile in game.sequence {
            lit = tile
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            lit = nil
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
        }
        phase = .input
    }

    private func handleTap(_ tile: Int) {
        guard phase == .input else { return }
        flash(tile)
        switch game.tap(tile) {
        case .correct:
            break
        case .completed:
            phase = .done
            onComplete()
        case .wrong:
            phase = .wrong
            var rng = SystemRandomNumberGenerator()
            game.regenerate(using: &rng)
            playbackID += 1
        }
    }

    private func flash(_ tile: Int) {
        tapped = tile
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            if tapped == tile { tapped = nil }
        }
    }
}
