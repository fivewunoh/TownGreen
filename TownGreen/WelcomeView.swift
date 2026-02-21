//
//  WelcomeView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                Spacer()

                VStack(spacing: 12) {
                    Text("TownGreen")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your Local Community")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
}
