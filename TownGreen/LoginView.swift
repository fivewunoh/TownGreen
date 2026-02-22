//
//  LoginView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
            } header: {
                Text("Log in")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
            }

            if let error = authManager.errorMessage {
                Section {
                    Text(error)
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await authManager.signIn(
                            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password: password
                        )
                    }
                } label: {
                    HStack {
                        Spacer()
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Log In")
                                .font(Font.TownGreenFonts.button)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Log In")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
        }
        .onAppear { authManager.clearError() }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthManager())
    }
}
