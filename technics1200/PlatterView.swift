//
//  PlatterView.swift
//  technics1200
//
//  The aluminium platter with stroboscopic rim dots, the audio-reactive
//  vinyl record, the centre label and the chrome spindle.
//

import SwiftUI

struct PlatterView: View {
    var diameter: CGFloat
    var angle: Double
    var level: Double
    var bands: SIMD3<Double>
    var title: String

    var body: some View {
        ZStack {
            aluminiumPlatter
                .rotationEffect(.degrees(angle))

            VinylRecordView(diameter: diameter * 0.9,
                            level: level,
                            bands: bands,
                            title: title)
                .rotationEffect(.degrees(angle))

            // Fixed light reflection sweeping across the spinning surface.
            sheen
                .frame(width: diameter, height: diameter)
                .allowsHitTesting(false)

            spindle
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.6), radius: 18, x: 0, y: 14)
    }

    // MARK: Aluminium platter + strobe dots

    private var aluminiumPlatter: some View {
        ZStack {
            Circle()
                .fill(Deck.brushedMetal())
                .overlay(Circle().fill(
                    RadialGradient(colors: [.white.opacity(0.18), .clear],
                                   center: .init(x: 0.35, y: 0.3),
                                   startRadius: 0, endRadius: diameter * 0.6)))
                .overlay(Circle().strokeBorder(Color.black.opacity(0.35), lineWidth: 2))

            StrobeDots(diameter: diameter)
        }
        .frame(width: diameter, height: diameter)
    }

    private var sheen: some View {
        Circle()
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white.opacity(0.0), location: 0.0),
                        .init(color: .white.opacity(0.10), location: 0.08),
                        .init(color: .white.opacity(0.0), location: 0.2),
                        .init(color: .white.opacity(0.0), location: 0.5),
                        .init(color: .white.opacity(0.07), location: 0.58),
                        .init(color: .white.opacity(0.0), location: 0.7),
                        .init(color: .white.opacity(0.0), location: 1.0),
                    ]),
                    center: .center,
                    angle: .degrees(-35)))
            .blendMode(.screen)
    }

    private var spindle: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.5))
                .frame(width: diameter * 0.05, height: diameter * 0.05)
            Circle()
                .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: diameter * 0.032, height: diameter * 0.032)
                .overlay(Circle().fill(.white.opacity(0.7))
                    .frame(width: diameter * 0.012, height: diameter * 0.012)
                    .offset(x: -diameter * 0.006, y: -diameter * 0.006))
        }
        .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
    }
}

/// Four rows of fine dots around the platter edge — the stroboscopic ring.
private struct StrobeDots: View {
    var diameter: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = size.width / 2 - 2
            let rows = [outer - 3, outer - 9, outer - 15, outer - 21]
            let counts = [180, 168, 156, 144]
            for (ri, radius) in rows.enumerated() {
                let count = counts[ri]
                let dot = max(0.8, diameter * 0.0022)
                for i in 0..<count {
                    let a = Double(i) / Double(count) * 2 * .pi
                    let p = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
                    let rect = CGRect(x: p.x - dot, y: p.y - dot, width: dot * 2, height: dot * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.85)))
                }
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
