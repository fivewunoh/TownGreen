//
//  SignUpView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var didSignUp = false

    var body: some View {
        Form {
            if didSignUp {
                Section {
                    Text("Please check your email to verify your account.")
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(Color.darkGreen)
                }
            } else {
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
                        .textContentType(.newPassword)
                        .padding(12)
                        .background(Color.townGreenCard(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.lightGreen, lineWidth: 1)
                        )
                } header: {
                    Text("Create account")
                        .font(Font.TownGreenFonts.sectionHeader)
                        .foregroundStyle(Color.primaryGreen)
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
                            let success = await authManager.signUp(
                                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                password: password
                            )
                            if success {
                                didSignUp = true
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sign Up")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
        }
        .onAppear { authManager.clearError() }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthManager())
    }
}
