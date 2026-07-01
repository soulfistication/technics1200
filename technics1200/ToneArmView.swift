//
//  ToneArmView.swift
//  technics1200
//
//  An S-shaped tonearm in the style of the SL-1200: gimbal bearing + height
//  collar at the rear-right, counterweight + anti-skate at the back, S-curved
//  tube and a removable headshell with stylus at the tip. The arm parks on its
//  rest when stopped and swings onto the record, tracking inward as it plays.
//

import SwiftUI

struct ToneArmView: View {
    var size: CGSize
    var engaged: Bool
    var progress: Double
    var platterCenter: CGPoint
    var recordRadius: CGFloat

    // Pivot (gimbal) position — rear right of the deck.
    private var pivot: CGPoint {
        CGPoint(x: size.width * 0.83, y: size.height * 0.20)
    }

    // Stylus contact points on the record (right-hand side of the platter).
    private var outerContact: CGPoint {
        let a = -18.0 * .pi / 180
        let r = recordRadius * 0.99
        return CGPoint(x: platterCenter.x + cos(a) * r,
                       y: platterCenter.y - sin(a) * r)
    }
    private var innerContact: CGPoint {
        let a = -30.0 * .pi / 180
        let r = recordRadius * 0.42
        return CGPoint(x: platterCenter.x + cos(a) * r,
                       y: platterCenter.y - sin(a) * r)
    }

    private var armLength: CGFloat {
        hypot(outerContact.x - pivot.x, outerContact.y - pivot.y)
    }

    private func angle(to p: CGPoint) -> Double {
        atan2(p.y - pivot.y, p.x - pivot.x)
    }

    /// Rotation applied around the pivot, relative to the "outer groove" pose.
    private var rotation: Double {
        let outer = angle(to: outerContact)
        if engaged {
            let inner = angle(to: innerContact)
            return (inner - outer) * 180 / .pi * progress
        } else {
            // Lift just off the outer edge and park on the rest to the right.
            return -13
        }
    }

    var body: some View {
        ZStack {
            armRestAndControls
            Canvas { ctx, _ in drawArm(ctx) }
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(rotation),
                                anchor: UnitPoint(x: pivot.x / size.width,
                                                  y: pivot.y / size.height))
                .animation(.easeInOut(duration: 0.45), value: engaged)
                .shadow(color: .black.opacity(0.35), radius: 5, x: -3, y: 6)
            pivotHousing
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Arm drawing

    private func drawArm(_ ctx: GraphicsContext) {
        let dir = CGVector(dx: cos(angle(to: outerContact)), dy: sin(angle(to: outerContact)))
        let perp = CGVector(dx: -dir.dy, dy: dir.dx)
        func pt(_ along: CGFloat, _ side: CGFloat) -> CGPoint {
            CGPoint(x: pivot.x + dir.dx * along + perp.dx * side,
                    y: pivot.y + dir.dy * along + perp.dx * 0 + perp.dy * side)
        }
        let L = armLength
        let tubeColor = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Color(white: 0.78), Color(white: 0.35)]),
            startPoint: pivot, endPoint: outerContact)

        // Counterweight stub + weight behind the pivot.
        let cwEnd = pt(-L * 0.34, 0)
        var stub = Path()
        stub.move(to: pivot)
        stub.addLine(to: cwEnd)
        ctx.stroke(stub, with: .color(Color(white: 0.3)), style: .init(lineWidth: max(4, L * 0.03), lineCap: .round))

        let cwR = max(10, L * 0.075)
        ctx.fill(Path(ellipseIn: CGRect(x: cwEnd.x - cwR, y: cwEnd.y - cwR, width: cwR * 2, height: cwR * 2)),
                 with: .radialGradient(Gradient(colors: [Color(white: 0.25), .black]),
                                       center: cwEnd, startRadius: 0, endRadius: cwR))
        // Anti-skate ring near pivot.
        let asPos = pt(-L * 0.12, L * 0.07)
        let asR = max(5, L * 0.035)
        ctx.fill(Path(ellipseIn: CGRect(x: asPos.x - asR, y: asPos.y - asR, width: asR * 2, height: asR * 2)),
                 with: .color(Color(white: 0.2)))

        // S-curved tube from pivot to the headshell base.
        let headBase = pt(L * 0.80, 0)
        var tube = Path()
        tube.move(to: pivot)
        tube.addCurve(to: headBase,
                      control1: pt(L * 0.32, L * 0.05),
                      control2: pt(L * 0.60, -L * 0.05))
        ctx.stroke(tube, with: tubeColor, style: .init(lineWidth: max(4, L * 0.028), lineCap: .round))
        // Tube highlight.
        ctx.stroke(tube, with: .color(.white.opacity(0.5)), style: .init(lineWidth: max(1, L * 0.006), lineCap: .round))

        // Headshell — angled finger lift + cartridge body + stylus.
        let tip = pt(L, 0)
        let neck = pt(L * 0.88, L * 0.02)
        var shell = Path()
        shell.move(to: headBase)
        shell.addLine(to: neck)
        shell.addLine(to: tip)
        ctx.stroke(shell, with: .color(Color(white: 0.15)), style: .init(lineWidth: max(7, L * 0.05), lineCap: .round, lineJoin: .round))

        // Cartridge block.
        let cartR = max(4, L * 0.03)
        ctx.fill(Path(roundedRect: CGRect(x: tip.x - cartR, y: tip.y - cartR, width: cartR * 2.2, height: cartR * 2),
                                    cornerRadius: 2),
                 with: .color(Color(red: 0.1, green: 0.1, blue: 0.12)))
        // Stylus contact glow.
        let sr = max(1.5, L * 0.012)
        ctx.fill(Path(ellipseIn: CGRect(x: tip.x - sr, y: tip.y - sr, width: sr * 2, height: sr * 2)),
                 with: .color(.white.opacity(0.9)))
    }

    // MARK: Static furniture

    private var pivotHousing: some View {
        ZStack {
            Circle().fill(Deck.brushedMetal())
                .frame(width: size.width * 0.075, height: size.width * 0.075)
                .overlay(Circle().strokeBorder(.black.opacity(0.4), lineWidth: 1.5))
            Circle().fill(Color(white: 0.2))
                .frame(width: size.width * 0.03, height: size.width * 0.03)
        }
        .position(pivot)
        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
    }

    private var armRestAndControls: some View {
        // Arm rest post + Y-clip just off the platter's right edge.
        let restPos = CGPoint(x: size.width * 0.735, y: size.height * 0.74)
        return ZStack {
            Capsule()
                .fill(Deck.brushedMetal())
                .frame(width: size.width * 0.016, height: size.height * 0.10)
            Image(systemName: "tuningfork")
                .font(.system(size: size.width * 0.03, weight: .black))
                .foregroundStyle(Color(white: 0.25))
                .offset(y: -size.height * 0.05)
        }
        .position(restPos)
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }
}
