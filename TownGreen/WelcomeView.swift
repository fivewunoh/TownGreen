//
//  WelcomeView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                Spacer()

                VStack(spacing: 12) {
                    Text("TownGreen")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                    Text("Your Local Community")
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(Color.primaryGreen.opacity(0.7))
                }

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Sign Up")
                            .font(Font.TownGreenFonts.button)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryGreen)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Log In")
                            .font(Font.TownGreenFonts.button)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryGreen, lineWidth: 2)
                            )
                            .foregroundStyle(Color.primaryGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.townGreenBackground(for: colorScheme))
            .navigationTitle("TownGreen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TownGreen")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
}
