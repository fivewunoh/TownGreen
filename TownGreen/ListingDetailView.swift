//
//  ListingDetailView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct ListingDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var listing: Listing
    @State private var currentUserId: UUID?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var isUpdatingSold = false

    private var isOwner: Bool {
        guard let current = currentUserId, let listingUser = listing.userId else { return false }
        return current == listingUser
    }

    private var isSold: Bool {
        listing.isSold ?? false
    }

    init(listing: Listing) {
        _listing = State(initialValue: listing)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                imageSectionWithSoldBanner
                contentSection
                if isOwner {
                    ownerActionsSection
                }
            }
        }
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Listing")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
        }
        .task {
            await loadCurrentUser()
        }
        .alert("Delete listing?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteListing() }
            }
        } message: {
            Text("Are you sure you want to delete this listing?")
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditListingView(listing: listing) { updated in
                    listing = updated
                    showEditSheet = false
                }
            }
        }
    }

    @ViewBuilder
    private var imageSectionWithSoldBanner: some View {
        ZStack(alignment: .topLeading) {
            if let urlString = listing.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: isSold ? 0 : 16,
                        bottomTrailingRadius: isSold ? 0 : 16
                    )
                )
            } else {
                imagePlaceholder
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: isSold ? 0 : 16,
                            bottomTrailingRadius: isSold ? 0 : 16
                        )
                    )
            }

            if isSold {
                soldBanner
            }
        }
    }

    private var soldBanner: some View {
        Text("SOLD")
            .font(Font.TownGreenFonts.sectionHeader)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.darkGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(12)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(listing.title ?? "Untitled")
                .font(Font.TownGreenFonts.title)
                .foregroundStyle(Color.textPrimary(for: colorScheme))

            Text(formatPrice(listing.price ?? 0))
                .font(Font.TownGreenFonts.price)
                .foregroundStyle(Color.textPrimary(for: colorScheme))

            if let category = listing.category, !category.isEmpty {
                DetailRow(label: "Category", value: category)
            }
            if let location = listing.location, !location.isEmpty {
                DetailRow(label: "Location", value: location)
            }
            if let createdAt = listing.createdAt {
                DetailRow(label: "Posted", value: TownGreenDateFormatter.formatCreatedAt(from: createdAt))
            }

            if let description = listing.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(Font.TownGreenFonts.sectionHeader)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                    Text(description)
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(Color.textPrimary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder
    private var ownerActionsSection: some View {
        VStack(spacing: 12) {
            if !isSold {
                Button {
                    Task { await markAsSold() }
                } label: {
                    HStack {
                        Spacer()
                        if isUpdatingSold {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Mark as Sold")
                                .font(Font.TownGreenFonts.button)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isUpdatingSold)
            }

            HStack(spacing: 12) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit Listing")
                        .font(Font.TownGreenFonts.button)
                        .foregroundStyle(Color.primaryGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryGreen, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)

                if currentUserId == listing.userId {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Listing")
                            .font(Font.TownGreenFonts.button)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color.townGreenCard(for: colorScheme)
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }

    private func loadCurrentUser() async {
        if let session = try? await SupabaseClient.shared.auth.session {
            await MainActor.run {
                currentUserId = session.user.id
            }
        }
    }

    // RLS reminder: Supabase listings table should only allow DELETE when auth.uid() = user_id.
    private func deleteListing() async {
        do {
            try await SupabaseClient.shared
                .from("listings")
                .delete()
                .eq("id", value: listing.id)
                .execute()
            await MainActor.run {
                dismiss()
            }
        } catch {
            // Optionally set error state
        }
    }

    private func markAsSold() async {
        isUpdatingSold = true
        defer { isUpdatingSold = false }
        let payload = MarkAsSoldPayload(isSold: true)
        do {
            try await SupabaseClient.shared
                .from("listings")
                .update(payload)
                .eq("id", value: listing.id)
                .execute()
            await MainActor.run {
                listing = Listing(
                    id: listing.id,
                    title: listing.title,
                    description: listing.description,
                    price: listing.price,
                    category: listing.category,
                    location: listing.location,
                    userId: listing.userId,
                    imageUrl: listing.imageUrl,
                    isSold: true,
                    createdAt: listing.createdAt
                )
            }
        } catch {
            // Optionally set error state
        }
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(listing: Listing(
            id: 1,
            title: "Vintage Bike",
            description: "Great condition, barely used.",
            price: 150,
            category: "Sports",
            location: "Downtown",
            userId: UUID(),
            imageUrl: nil,
            isSold: nil,
            createdAt: nil
        ))
    }
}
