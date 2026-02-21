//
//  AuthManager.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation
import Combine
import Supabase

final class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false

    private var authTask: Task<Void, Never>?

    init() {
        authTask = Task { [weak self] in
            await self?.observeSession()
        }
    }

    deinit {
        authTask?.cancel()
    }

    private func observeSession() async {
        for await (_, session) in SupabaseClient.shared.auth.authStateChanges {
            await MainActor.run {
                self.isLoggedIn = (session != nil)
            }
        }
    }

    func signIn(email: String, password: String) async {
        do {
            _ = try await SupabaseClient.shared.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            // Caller can handle error
        }
    }

    func signUp(email: String, password: String) async {
        do {
            _ = try await SupabaseClient.shared.auth.signUp(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            // Caller can handle error
        }
    }

    func signOut() async {
        do {
            try await SupabaseClient.shared.auth.signOut()
            await MainActor.run {
                self.isLoggedIn = false
            }
        } catch {
            // Caller can handle error
        }
    }
}
