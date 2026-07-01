//
//  VinylRecordView.swift
//  technics1200
//
//  A 12" record whose grooves light up with the music: low frequencies push
//  the inner rings, mids the middle, highs the outer edge, and overall level
//  drives a pulsing halo so you can literally watch the peaks and quiet parts.
//

import SwiftUI

struct VinylRecordView: View {
    var diameter: CGFloat
    var level: Double
    var bands: SIMD3<Double>
    var title: String

    var body: some View {
        ZStack {
            base
            Canvas { ctx, size in
                drawGrooves(ctx, size)
                drawReactiveRings(ctx, size)
            }
            .frame(width: diameter, height: diameter)
            .blendMode(.screen)

            label
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        // Very subtle breathing with the music.
        .scaleEffect(1.0 + level * 0.012)
    }

    private var base: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Deck.vinylSheen.opacity(0.6), Deck.vinyl, .black],
                    center: .center, startRadius: 0, endRadius: diameter / 2))
            .overlay(
                Circle().fill(
                    AngularGradient(colors: [
                        .white.opacity(0.05), .clear, .white.opacity(0.04),
                        .clear, .white.opacity(0.05), .clear, .white.opacity(0.04), .clear
                    ], center: .center))
                .blendMode(.screen))
            .overlay(Circle().strokeBorder(.black, lineWidth: 1))
    }

    // Static groove texture.
    private func drawGrooves(_ ctx: GraphicsContext, _ size: CGSize) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = size.width / 2 * 0.97
        let labelR = size.width / 2 * 0.34
        let count = 80
        for i in 0..<count {
            let t = Double(i) / Double(count)
            let r = labelR + (outer - labelR) * t
            let op = 0.04 + 0.04 * (i % 3 == 0 ? 1.0 : 0.3)
            var path = Path()
            path.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.stroke(path, with: .color(.white.opacity(op)), lineWidth: 0.6)
        }
    }

    // Glowing rings that respond to the three frequency bands + overall level.
    private func drawReactiveRings(_ ctx: GraphicsContext, _ size: CGSize) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = size.width / 2 * 0.95
        let labelR = size.width / 2 * 0.36
        let rings = 46

        let high = bands.z, mid = bands.y, low = bands.x
        let warm = Color(red: 1.0, green: 0.5, blue: 0.18)   // low / inner
        let green = Color(red: 0.3, green: 1.0, blue: 0.55)  // mid
        let cyan = Color(red: 0.35, green: 0.8, blue: 1.0)   // high / outer

        for i in 0..<rings {
            let t = Double(i) / Double(rings - 1)          // 0 inner -> 1 outer
            let r = labelR + (outer - labelR) * t

            // Pick band energy by radial zone with smooth crossfades.
            let bandEnergy: Double
            let color: Color
            if t < 0.4 {
                bandEnergy = low
                color = warm
            } else if t < 0.72 {
                bandEnergy = mid
                color = green
            } else {
                bandEnergy = high
                color = cyan
            }

            let intensity = min(1.0, bandEnergy * 0.9 + level * 0.6)
            guard intensity > 0.02 else { continue }

            var path = Path()
            path.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            // Glow pass (wide, faint) then crisp groove line.
            ctx.stroke(path, with: .color(color.opacity(intensity * 0.16)),
                       lineWidth: 2.5 + intensity * 4)
            ctx.stroke(path, with: .color(color.opacity(intensity * 0.85)),
                       lineWidth: 1.3)
        }

        // Bright outer halo that flares on overall peaks.
        if level > 0.04 {
            var halo = Path()
            let r = outer
            halo.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.stroke(halo, with: .color(.white.opacity(min(0.6, level * 0.8))),
                       lineWidth: 1 + level * 3)
        }
    }

    private var label: some View {
        let labelD = diameter * 0.34
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [
                        Color(red: 0.86, green: 0.1, blue: 0.12),
                        Color(red: 0.62, green: 0.05, blue: 0.08)
                    ], center: .center, startRadius: 0, endRadius: labelD / 2))
            Circle().stroke(.black.opacity(0.4), lineWidth: 1)
                .frame(width: labelD * 0.98, height: labelD * 0.98)

            VStack(spacing: labelD * 0.04) {
                Text("Technics")
                    .font(.system(size: labelD * 0.12, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Rectangle().fill(.white.opacity(0.7))
                    .frame(width: labelD * 0.5, height: 1)
                Text(title)
                    .font(.system(size: labelD * 0.075, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .frame(width: labelD * 0.74)
                    .minimumScaleFactor(0.4)
                Text("33⅓ RPM • STEREO")
                    .font(.system(size: labelD * 0.05, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, labelD * 0.08)
        }
        .frame(width: labelD, height: labelD)
    }
}
