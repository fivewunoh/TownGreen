//
//  TownGreenApp.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

@main
struct TownGreenApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
