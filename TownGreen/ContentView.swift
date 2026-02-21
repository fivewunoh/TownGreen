//
//  ContentView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PlaceholderTab(title: "For Sale")
                .tabItem {
                    Label("For Sale", systemImage: "tag.fill")
                }
            PlaceholderTab(title: "Events")
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
            PlaceholderTab(title: "Services")
                .tabItem {
                    Label("Services", systemImage: "wrench.and.screwdriver.fill")
                }
            PlaceholderTab(title: "News")
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
        }
    }
}

struct PlaceholderTab: View {
    let title: String

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text(title)
                    .font(.title)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
