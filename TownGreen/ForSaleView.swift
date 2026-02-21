//
//  ForSaleView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct ForSaleView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var listings: [Listing] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateListing = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && listings.isEmpty {
                    ProgressView("Loading listings…")
                        .font(Font.TownGreenFonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to load listings",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(listings) { listing in
                                NavigationLink {
                                    ListingDetailView(listing: listing)
                                } label: {
                                    ListingCard(listing: listing, colorScheme: colorScheme)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.townGreenBackground(for: colorScheme))
            .navigationTitle("For Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("For Sale")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateListing = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.primaryGreen)
                    }
                }
            }
            .task {
                await fetchListings()
            }
            .onAppear {
                Task { await fetchListings() }
            }
            .refreshable {
                await fetchListings()
            }
            .sheet(isPresented: $showCreateListing) {
                NavigationStack {
                    CreateListingView {
                        showCreateListing = false
                        await fetchListings()
                    }
                }
            }
        }
    }

    private func fetchListings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched: [Listing] = try await SupabaseClient.shared
                .from("listings")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            await MainActor.run {
                self.listings = fetched
                self.listings.sort { !($0.isSold ?? false) && ($1.isSold ?? false) }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct ListingCard: View {
    let listing: Listing
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(listing.title ?? "Untitled")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if listing.isSold == true {
                        Text("SOLD")
                            .font(Font.TownGreenFonts.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.darkGreen.opacity(0.9))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
                HStack {
                    Text(formatPrice(listing.price ?? 0))
                        .font(Font.TownGreenFonts.price)
                        .foregroundStyle(Color.primaryGreen)
                    Spacer()
                    if let category = listing.category, !category.isEmpty {
                        Text(category)
                            .font(Font.TownGreenFonts.caption)
                            .foregroundStyle(Color.darkGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.lightGreen)
                            .clipShape(Capsule())
                    }
                }
                if let location = listing.location, !location.isEmpty {
                    Text(location)
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(Color.darkGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let urlString = listing.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        thumbnailPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.townGreenCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 4, x: 0, y: 2)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.townGreenCard(for: colorScheme)
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
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
    ForSaleView()
}
