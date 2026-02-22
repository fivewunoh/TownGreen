//
//  SettingsView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

enum ColorSchemeOption: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("colorScheme") private var storedColorScheme: String = ColorSchemeOption.system.rawValue
    @State private var userEmail: String?
    @State private var isLoadingEmail = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isLoadingEmail {
                        HStack {
                            Text("Loading…")
                                .font(Font.TownGreenFonts.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            ProgressView()
                        }
                    } else if let email = userEmail {
                        HStack {
                            Text("Email")
                                .font(Font.TownGreenFonts.sectionHeader)
                                .foregroundStyle(Color.textPrimary(for: colorScheme))
                            Spacer()
                            Text(email)
                                .font(Font.TownGreenFonts.body)
                                .foregroundStyle(Color.textPrimary(for: colorScheme))
                        }
                    }
                    Button(role: .destructive) {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    } label: {
                        Text("Log Out")
                            .font(Font.TownGreenFonts.button)
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Account")
                        .font(Font.TownGreenFonts.sectionHeader)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                }

                Section {
                    Picker("Appearance", selection: $storedColorScheme) {
                        ForEach(ColorSchemeOption.allCases, id: \.rawValue) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                        .font(Font.TownGreenFonts.sectionHeader)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                }

                Section {
                    HStack {
                        Text("Version")
                            .font(Font.TownGreenFonts.sectionHeader)
                            .foregroundStyle(Color.textPrimary(for: colorScheme))
                        Spacer()
                        Text("1.0.0")
                            .font(Font.TownGreenFonts.body)
                            .foregroundStyle(Color.textPrimary(for: colorScheme))
                    }
                    HStack {
                        Text("TownGreen — French Valley & Winchester Community")
                            .font(Font.TownGreenFonts.body)
                            .foregroundStyle(Color.textPrimary(for: colorScheme))
                    }
                } header: {
                    Text("About")
                        .font(Font.TownGreenFonts.sectionHeader)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.townGreenBackground(for: colorScheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Font.TownGreenFonts.button)
                    .foregroundStyle(Color.primaryGreen)
                }
            }
            .task {
                await loadUserEmail()
            }
        }
    }

    private func loadUserEmail() async {
        isLoadingEmail = true
        defer { isLoadingEmail = false }
        if let session = try? await SupabaseClient.shared.auth.session {
            await MainActor.run {
                userEmail = session.user.email
            }
        } else {
            await MainActor.run {
                userEmail = nil
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
