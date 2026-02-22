//
//  ProfileManager.swift
//  TownGreen
//

import Foundation
import Combine
import Supabase

@MainActor
final class ProfileManager: ObservableObject {
    @Published private(set) var currentProfile: Profile?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var profileCache: [String: Profile] = [:]

    /// Fetch profile by user id (cached)
    func fetchProfile(userId: String) async -> Profile? {
        if let cached = profileCache[userId] {
            return cached
        }
        do {
            let list: [Profile] = try await SupabaseClient.shared
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            let profile = list.first
            if let profile = profile {
                profileCache[userId] = profile
            }
            return profile
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Update existing profile or create if missing
    func updateProfile(userId: String, fullName: String?, username: String?, neighborhood: String?, avatarUrl: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let existing: [Profile] = try await SupabaseClient.shared
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            let payload = UpdateProfileRequest(
                userId: userId,
                username: username,
                fullName: fullName,
                avatarUrl: avatarUrl,
                neighborhood: neighborhood
            )

            if let profile = existing.first, let profileId = profile.id {
                try await SupabaseClient.shared
                    .from("profiles")
                    .update(payload)
                    .eq("id", value: profileId)
                    .execute()
            } else {
                try await SupabaseClient.shared
                    .from("profiles")
                    .insert(payload)
                    .execute()
            }

            profileCache[userId] = nil
            let current = await currentUserId()
            if userId == current {
                currentProfile = await fetchProfile(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Ensure the current user has a profile row (call on login)
    func createProfileIfNeeded() async {
        guard let userId = await currentUserId() else { return }
        do {
            let existing: [Profile] = try await SupabaseClient.shared
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            if existing.isEmpty {
                let payload = UpdateProfileRequest(
                    userId: userId,
                    username: nil,
                    fullName: nil,
                    avatarUrl: nil,
                    neighborhood: nil
                )
                try await SupabaseClient.shared
                    .from("profiles")
                    .insert(payload)
                    .execute()
            }

            currentProfile = await fetchProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Load current user's profile into currentProfile
    func loadCurrentProfile() async {
        guard let userId = await currentUserId() else {
            currentProfile = nil
            return
        }
        currentProfile = await fetchProfile(userId: userId)
    }

    /// Current auth user id (UUID string)
    func currentUserId() async -> String? {
        (try? await SupabaseClient.shared.auth.session)?.user.id.uuidString
    }

    func clearError() {
        errorMessage = nil
    }
}
