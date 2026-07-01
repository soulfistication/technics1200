//
//  Theme.swift
//  technics1200
//
//  Shared colours and gradients for the turntable chrome.
//

import SwiftUI

enum Deck {
    // Classic SL-1200 "silver" body. (A MK2 in silver finish.)
    static let bodyTop = Color(red: 0.78, green: 0.79, blue: 0.81)
    static let bodyBottom = Color(red: 0.62, green: 0.63, blue: 0.66)
    static let bodyEdge = Color(red: 0.40, green: 0.41, blue: 0.44)

    static let platterDark = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let platterRim = Color(red: 0.30, green: 0.31, blue: 0.34)
    static let platterMetal = Color(red: 0.52, green: 0.53, blue: 0.56)

    static let vinyl = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let vinylSheen = Color(red: 0.20, green: 0.20, blue: 0.23)

    static let redStrobe = Color(red: 1.0, green: 0.18, blue: 0.12)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.2)

    static let bodyGradient = LinearGradient(
        colors: [bodyTop, bodyBottom],
        startPoint: .top, endPoint: .bottom)

    static func brushedMetal(angle: Angle = .degrees(45)) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(white: 0.78), Color(white: 0.55), Color(white: 0.82),
                Color(white: 0.5), Color(white: 0.8), Color(white: 0.58),
                Color(white: 0.78)
            ]),
            center: .center)
    }
}

/// A recessed inset look used for control wells.
struct RecessedWell: ViewModifier {
    var cornerRadius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.55)
                        .shadow(.inner(color: .black.opacity(0.9), radius: 5, x: 0, y: 3)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func recessedWell(cornerRadius: CGFloat = 14) -> some View {
        modifier(RecessedWell(cornerRadius: cornerRadius))
    }
}
