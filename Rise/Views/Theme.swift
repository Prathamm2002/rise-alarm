//
//  Theme.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

enum Theme {
    static let background = Color(hex: 0x0A0A0F)
    static let card = Color(hex: 0x16161D)
    static let cardRaised = Color(hex: 0x20202A)
    /// "Sunrise" accent.
    static let accent = Color(hex: 0xFF6B35)
    static let accentSoft = Color(hex: 0xFF6B35).opacity(0.18)
    static let secondaryText = Color.white.opacity(0.55)
    static let success = Color(hex: 0x3DDC84)
    static let danger = Color(hex: 0xFF453A)

    static let sunriseGradient = LinearGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF4E50)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)

    static func timeFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .thin, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Rounded dark card container.
struct CardBackground: ViewModifier {
    var color: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(color, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func riseCard(_ color: Color = Theme.card) -> some View {
        modifier(CardBackground(color: color))
    }
}

/// Large filled accent button.
struct PrimaryButtonStyle: ButtonStyle {
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? AnyShapeStyle(Theme.sunriseGradient) : AnyShapeStyle(Color.white.opacity(0.12)),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
