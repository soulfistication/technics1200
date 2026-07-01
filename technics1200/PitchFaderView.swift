//
//  PitchFaderView.swift
//  technics1200
//
//  The ±8% pitch fader. Up = faster, down = slower, with a centre detent and
//  the familiar engraved scale. Double-tap to snap back to 0%.
//

import SwiftUI

struct PitchFaderView: View {
    /// -8 ... +8 percent.
    var value: Double
    var onChange: (Double) -> Void

    private let range = 8.0

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let travel = h * 0.82
            let top = (h - travel) / 2
            let frac = (value + range) / (range * 2)        // 0 (bottom) ... 1 (top)
            let thumbY = top + travel * (1 - frac)

            ZStack {
                ticks(h: h, w: w, travel: travel, top: top)

                // Recessed slot.
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: w * 0.12, height: travel + w * 0.1)
                    .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1))
                    .position(x: w / 2, y: h / 2)

                // Centre (0%) red reference line.
                Rectangle().fill(Deck.redStrobe.opacity(0.9))
                    .frame(width: w * 0.5, height: 2)
                    .position(x: w / 2, y: top + travel / 2)

                thumb(w: w)
                    .position(x: w / 2, y: thumbY)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let f = 1 - min(1, max(0, (g.location.y - top) / travel))
                        var v = (f * 2 - 1) * range
                        if abs(v) < 0.25 { v = 0 }            // soft centre detent
                        onChange(v)
                    }
            )
            .onTapGesture(count: 2) { onChange(0) }
        }
    }

    private func thumb(w: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.32), Color(white: 0.12)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.66, height: w * 0.42)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.black.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
            // Indicator line.
            Rectangle().fill(.white.opacity(0.9))
                .frame(width: w * 0.62, height: 2)
        }
    }

    private func ticks(h: CGFloat, w: CGFloat, travel: CGFloat, top: CGFloat) -> some View {
        Canvas { ctx, _ in
            let steps = 16
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let y = top + travel * t
                let major = (i % 4 == 0)
                let len: CGFloat = major ? w * 0.22 : w * 0.12
                var path = Path()
                path.move(to: CGPoint(x: w * 0.5 + w * 0.1, y: y))
                path.addLine(to: CGPoint(x: w * 0.5 + w * 0.1 + len, y: y))
                ctx.stroke(path, with: .color(.white.opacity(major ? 0.6 : 0.3)),
                           lineWidth: major ? 1.5 : 1)
            }
        }
    }
}
