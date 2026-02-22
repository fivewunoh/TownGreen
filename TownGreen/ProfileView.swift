//
//  ProfileView.swift
//  TownGreen
//

import SwiftUI
import Supabase

enum ProfileTab: String, CaseIterable {
    case listings = "Listings"
    case events = "Events"
    case services = "Services"
}

struct ProfileView: View {
    let userId: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager

    @State private var profile: Profile?
    @State private var selectedTab: ProfileTab = .listings
    @State private var listings: [Listing] = []
    @State private var events: [Event] = []
    @State private var services: [Service] = []
    @State private var isLoadingProfile = true
    @State private var isLoadingContent = false
    @State private var showEditProfile = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                trustSection
                Picker("", selection: $selectedTab) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                contentSection
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(profile?.displayName ?? "Profile")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isViewingSelf {
                    Button("Edit") {
                        showEditProfile = true
                    }
                    .font(Font.TownGreenFonts.button)
                    .foregroundStyle(Color.primaryGreen)
                }
            }
        }
        .task {
            await loadProfileAndContent()
        }
        .refreshable {
            await Task { await loadProfileAndContent() }.value
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(profile: profile, userId: userId) { updated in
                    profile = updated
                    showEditProfile = false
                }
                .environmentObject(profileManager)
            }
        }
    }

    @State private var isViewingSelf = false

    private var headerSection: some View {
        VStack(spacing: 16) {
            if isLoadingProfile {
                ProgressView()
                    .padding(.vertical, 24)
            } else {
                avatarView
                Text(profile?.displayName ?? "Member")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
                if let neighborhood = profile?.neighborhood, !neighborhood.isEmpty {
                    Text(neighborhood)
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                }
                if let createdAt = profile?.createdAt {
                    Text("Member since \(memberSinceString(createdAt))")
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(Color.textPrimary(for: colorScheme).opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var avatarView: some View {
        Group {
            if let urlString = profile?.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        avatarPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .onTapGesture {
            if isViewingSelf {
                showEditProfile = true
            }
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.lightGreen.opacity(0.3)
            Image(systemName: "person.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.primaryGreen)
        }
    }

    private var trustSection: some View {
        HStack {
            Text("Trust score")
                .font(Font.TownGreenFonts.sectionHeader)
                .foregroundStyle(Color.textPrimary(for: colorScheme))
            Spacer()
            Text("No ratings yet")
                .font(Font.TownGreenFonts.caption)
                .foregroundStyle(Color.textPrimary(for: colorScheme).opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.townGreenCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var contentSection: some View {
        if isLoadingContent {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            LazyVStack(spacing: 12) {
                switch selectedTab {
                case .listings:
                    ForEach(listings) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            ListingCard(listing: listing, colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                    }
                case .events:
                    ForEach(events) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            EventCard(event: event, colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                    }
                case .services:
                    ForEach(services) { service in
                        NavigationLink {
                            ServiceDetailView(service: service)
                        } label: {
                            ServiceCard(service: service, colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func memberSinceString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    private func loadProfileAndContent() async {
        isLoadingProfile = true
        let uid = await profileManager.currentUserId()
        await MainActor.run {
            isViewingSelf = (uid == userId)
        }
        profile = await profileManager.fetchProfile(userId: userId)
        await MainActor.run { isLoadingProfile = false }

        isLoadingContent = true
        await fetchListings()
        await fetchEvents()
        await fetchServices()
        await MainActor.run { isLoadingContent = false }
    }

    private func fetchListings() async {
        do {
            // listings table user_id is UUID; Supabase accepts UUID string
            let fetched: [Listing] = try await SupabaseClient.shared
                .from("listings")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            await MainActor.run { listings = fetched }
        } catch {
            await MainActor.run { listings = [] }
        }
    }

    private func fetchEvents() async {
        do {
            let fetched: [Event] = try await SupabaseClient.shared
                .from("events")
                .select()
                .eq("user_id", value: userId)
                .order("event_date", ascending: true)
                .execute()
                .value
            await MainActor.run { events = fetched }
        } catch {
            await MainActor.run { events = [] }
        }
    }

    private func fetchServices() async {
        do {
            let fetched: [Service] = try await SupabaseClient.shared
                .from("services")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            await MainActor.run { services = fetched }
        } catch {
            await MainActor.run { services = [] }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(userId: "00000000-0000-0000-0000-000000000000")
            .environmentObject(ProfileManager())
    }
}
