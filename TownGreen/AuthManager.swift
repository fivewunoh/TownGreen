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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }
        do {
            _ = try await SupabaseClient.shared.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run { self.isLoggedIn = true }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }

    func signUp(email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }
        do {
            _ = try await SupabaseClient.shared.auth.signUp(
                email: email,
                password: password
            )
            await MainActor.run { self.isLoggedIn = true }
            return true
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
            return false
        }
    }

    func signOut() async {
        await MainActor.run { errorMessage = nil }
        do {
            try await SupabaseClient.shared.auth.signOut()
            await MainActor.run { self.isLoggedIn = false }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
