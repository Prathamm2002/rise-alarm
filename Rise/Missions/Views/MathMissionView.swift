//
//  MathMissionView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct MathMissionView: View {
    let difficulty: Difficulty
    let target: Int
    @Binding var progress: Int
    let onComplete: () -> Void

    @State private var problem: MathProblem
    @State private var input = ""
    @State private var shakeTrigger = 0
    @State private var showWrong = false
    @FocusState private var focused: Bool

    init(difficulty: Difficulty, target: Int, progress: Binding<Int>, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.target = target
        self._progress = progress
        self.onComplete = onComplete
        var rng = SystemRandomNumberGenerator()
        self._problem = State(initialValue: MathGenerator.make(difficulty, using: &rng))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(problem.text + " = ?")
                .font(.system(size: 40, weight: .semibold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))

            TextField("Answer", text: $input)
                .keyboardType(.numberPad)
                .focused($focused)
                .font(.system(size: 34, weight: .medium, design: .rounded).monospacedDigit())
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .background(Theme.cardRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(showWrong ? Theme.danger : Color.clear, lineWidth: 2)
                )

            Text(showWrong ? "Not quite. Here is a new one." : "Solve to turn off the alarm")
                .font(.footnote)
                .foregroundStyle(showWrong ? Theme.danger : Theme.secondaryText)

            Button("Submit", action: submit)
                .buttonStyle(PrimaryButtonStyle(enabled: !input.isEmpty))
                .disabled(input.isEmpty)
        }
        .onAppear { focused = true }
    }

    private func submit() {
        if MathGenerator.check(input, against: problem) {
            progress += 1
            showWrong = false
            input = ""
            if progress >= target {
                focused = false
                onComplete()
            } else {
                nextProblem()
            }
        } else {
            showWrong = true
            input = ""
            withAnimation(.default) { shakeTrigger += 1 }
            nextProblem()
        }
    }

    private func nextProblem() {
        var rng = SystemRandomNumberGenerator()
        var next = MathGenerator.make(difficulty, using: &rng)
        // Avoid showing the exact same problem twice in a row.
        if next == problem { next = MathGenerator.make(difficulty, using: &rng) }
        problem = next
    }
}

/// Horizontal wiggle used for wrong answers.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}
