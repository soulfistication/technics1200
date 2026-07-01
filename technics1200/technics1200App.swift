//
//  technics1200App.swift
//  technics1200
//

import SwiftUI

@main
struct technics1200App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
