//
//  PhraseMissionView.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

struct PhraseMissionView: View {
    let target: Int
    @Binding var progress: Int
    let onComplete: () -> Void

    @State private var phrase: String
    @State private var input = ""
    @FocusState private var focused: Bool

    init(target: Int, progress: Binding<Int>, onComplete: @escaping () -> Void) {
        self.target = target
        self._progress = progress
        self.onComplete = onComplete
        var rng = SystemRandomNumberGenerator()
        self._phrase = State(initialValue: PhraseBank.random(using: &rng))
    }

    private var isMatch: Bool { PhraseBank.matches(input: input, target: phrase) }

    var body: some View {
        VStack(spacing: 20) {
            Text("Type exactly:")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(phrase)
                .font(.title2.weight(.medium))
                .foregroundStyle(.white)
                .textSelection(.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .riseCard()

            TextField("Start typing", text: $input, axis: .vertical)
                .lineLimit(2...4)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .font(.title3)
                .padding(14)
                .background(Theme.cardRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isMatch ? Theme.success : Color.white.opacity(0.08), lineWidth: 2)
                )

            Text("Capitals and punctuation count.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            Button("Done", action: submit)
                .buttonStyle(PrimaryButtonStyle(enabled: isMatch))
                .disabled(!isMatch)
        }
        .onAppear { focused = true }
        .onChange(of: input) { _, newValue in
            // Return key submits when the text already matches.
            if newValue.hasSuffix("\n") {
                if PhraseBank.matches(input: newValue, target: phrase) {
                    submit()
                } else {
                    input = String(newValue.dropLast())
                }
            }
        }
    }

    private func submit() {
        guard PhraseBank.matches(input: input, target: phrase) else { return }
        progress += 1
        input = ""
        if progress >= target {
            focused = false
            onComplete()
        } else {
            var rng = SystemRandomNumberGenerator()
            var next = PhraseBank.random(using: &rng)
            if next == phrase { next = PhraseBank.random(using: &rng) }
            phrase = next
        }
    }
}
