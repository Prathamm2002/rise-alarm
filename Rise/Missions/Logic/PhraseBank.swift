//
//  PhraseBank.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Phrases use only ASCII letters, spaces, commas, periods and "!" so iOS smart
/// punctuation can never make an exact match impossible.
enum PhraseBank {
    static let phrases: [String] = [
        "I am awake and ready to win today.",
        "Today I will do the hard thing first.",
        "Good morning, I choose to get up now.",
        "Small steps every day build big results.",
        "My bed is comfortable but my goals are better.",
        "I will drink a glass of water right now.",
        "Discipline is choosing what I want most.",
        "The early hours belong to me.",
        "Rise and shine, the day is waiting!",
        "I am grateful for this brand new morning.",
        "No snooze today, only forward.",
        "Energy comes from moving, so I will move.",
        "I keep promises to myself, starting now.",
        "Every morning is a fresh start.",
        "Open the curtains and let the light in.",
        "I am the kind of person who gets up on time.",
        "Focus, breathe, and begin the day.",
        "Coffee later, feet on the floor first.",
        "One more minute in bed is one less minute for me.",
        "Wake up, show up, and never give up!",
        "Today is a good day to be productive.",
        "I stretch, I smile, I start.",
        "Sleep was great, now it is time to shine.",
        "Mumbai is waking up, and so am I."
    ]

    static func random<G: RandomNumberGenerator>(using g: inout G) -> String {
        phrases.randomElement(using: &g) ?? phrases[0]
    }

    /// Exact, case-sensitive match after trimming leading/trailing whitespace and newlines.
    static func matches(input: String, target: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines) == target
    }
}
