//
//  Controls.swift
//  technics1200
//
//  Start/Stop button, the red stroboscope lamp and the pop-up target light.
//

import SwiftUI

/// Round START / STOP button (bottom-left of the deck).
struct StartStopButton: View {
    var isPlaying: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(white: 0.42), Color(white: 0.22)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().strokeBorder(.black.opacity(0.6), lineWidth: 2))
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 3)

                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.5), Color(white: 0.28)],
                                         center: .center, startRadius: 0, endRadius: 60))
                    .padding(10)

                // Inner play indicator strip.
                Capsule()
                    .fill(isPlaying ? Deck.amber : Color(white: 0.15))
                    .frame(width: 10, height: 26)
                    .shadow(color: isPlaying ? Deck.amber.opacity(0.9) : .clear, radius: 8)

                VStack {
                    Spacer()
                    Text(isPlaying ? "STOP" : "START")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// The red stroboscopic illuminator lamp. Glows while the deck is powered.
struct StrobeLamp: View {
    var active: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let flicker = active ? (0.85 + 0.15 * sin(t * 18)) : 0.12
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Deck.redStrobe.opacity(flicker))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(active ? 0.25 * flicker : 0))
                        .blur(radius: 2))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.black.opacity(0.5), lineWidth: 1))
                .shadow(color: Deck.redStrobe.opacity(active ? 0.9 * flicker : 0), radius: 12)
        }
    }
}

/// Pop-up white target light. Tap to raise the stalk and illuminate the stylus.
struct PopupLight: View {
    var raised: Bool
    var action: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Base housing.
                Circle()
                    .fill(Deck.brushedMetal())
                    .frame(width: w, height: w)
                    .overlay(Circle().strokeBorder(.black.opacity(0.4), lineWidth: 1))
                    .position(x: w / 2, y: h - w / 2)

                // Stalk + lamp head.
                VStack(spacing: 0) {
                    ZStack {
                        Capsule()
                            .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.5)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: w * 0.5, height: w * 0.5)
                        Circle()
                            .fill(.white)
                            .frame(width: w * 0.28, height: w * 0.28)
                            .shadow(color: .white.opacity(raised ? 0.95 : 0), radius: raised ? 16 : 0)
                            .overlay(Circle().fill(.white.opacity(raised ? 0.9 : 0.2)).blur(radius: 4))
                    }
                    Rectangle()
                        .fill(Color(white: 0.7))
                        .frame(width: w * 0.16, height: raised ? h * 0.55 : 1)
                }
                .frame(height: h, alignment: .bottom)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: raised)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
        }
    }
}
