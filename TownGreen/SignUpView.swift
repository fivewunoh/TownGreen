//
//  SignUpView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var didSignUp = false

    var body: some View {
        Form {
            if didSignUp {
                Section {
                    Text("Please check your email to verify your account.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                } header: {
                    Text("Create account")
                }

                if let error = authManager.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
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
                                    .tint(.primary)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                }
            }
        }
        .navigationTitle("Sign Up")
        .onAppear { authManager.clearError() }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthManager())
    }
}
