//
//  LoginView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                    .textContentType(.password)
            } header: {
                Text("Log in")
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
                                .tint(.primary)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            }
        }
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authManager.clearError() }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthManager())
    }
}
