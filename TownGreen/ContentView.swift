//
//  ContentView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("colorScheme") private var storedColorScheme: String = ColorSchemeOption.system.rawValue

    private var preferredScheme: ColorScheme? {
        switch storedColorScheme {
        case ColorSchemeOption.light.rawValue: return .light
        case ColorSchemeOption.dark.rawValue: return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.townGreenBackground(for: colorScheme))
        .preferredColorScheme(preferredScheme)
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            ForSaleView()
                .tabItem {
                    Label("For Sale", systemImage: "tag.fill")
                }
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
            ServicesView()
                .tabItem {
                    Label("Services", systemImage: "wrench.and.screwdriver.fill")
                }
            NewsView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
        }
        .tint(Color.primaryGreen)
        .background(Color.townGreenBackground(for: colorScheme))
    }
}

struct PlaceholderTab: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text(title)
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.darkGreen)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.townGreenBackground(for: colorScheme))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
