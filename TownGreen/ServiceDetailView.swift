//
//  ServiceDetailView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct ServiceDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var service: Service
    @State private var currentUserId: String?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    private var isOwner: Bool {
        guard let current = currentUserId, let serviceUserId = service.userId else { return false }
        return current.lowercased() == serviceUserId.lowercased()
    }

    init(service: Service) {
        _service = State(initialValue: service)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                contentSection
                if isOwner {
                    ownerActionsSection
                }
            }
        }
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Service")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
        }
        .task {
            await loadCurrentUser()
        }
        .alert("Delete service?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteService() }
            }
        } message: {
            Text("Are you sure you want to delete this service post?")
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditServiceView(service: service) { updated in
                    service = updated
                    showEditSheet = false
                }
            }
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let urlString = service.imageUrl, let url = URL(string: urlString) {
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                imagePlaceholder
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color.townGreenCard(for: colorScheme)
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(service.title ?? "Untitled")
                .font(Font.TownGreenFonts.title)
                .foregroundStyle(Color.textPrimary(for: colorScheme))

            Text((service.isOffered ?? true) ? "Offered" : "Wanted")
                .font(Font.TownGreenFonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.darkGreen)
                .clipShape(Capsule())

            if let category = service.category, !category.isEmpty {
                DetailRow(label: "Category", value: category)
            }
            if let price = service.priceRange, !price.isEmpty {
                DetailRow(label: "Price range", value: price)
            }
            if let location = service.location, !location.isEmpty {
                DetailRow(label: "Location", value: location)
            }
            if let contact = service.contactInfo, !contact.isEmpty {
                DetailRow(label: "Contact", value: contact)
            }

            if let description = service.description, !description.isEmpty {
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
            HStack(spacing: 12) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit Service")
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

                if currentUserId == service.userId {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Service")
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

    private func loadCurrentUser() async {
        let currentUser = try? await SupabaseClient.shared.auth.session.user
        await MainActor.run {
            currentUserId = currentUser?.id.uuidString
        }
    }

    private func deleteService() async {
        do {
            try await SupabaseClient.shared
                .from("services")
                .delete()
                .eq("id", value: service.id)
                .execute()
            await MainActor.run {
                dismiss()
            }
        } catch {
            // Optionally set error state
        }
    }
}

#Preview {
    NavigationStack {
        ServiceDetailView(service: Service(
            id: 1,
            createdAt: nil,
            title: "Lawn mowing",
            description: "Weekly mowing and edging.",
            category: "Lawn & Garden",
            userId: nil,
            contactInfo: "me@example.com",
            location: "Downtown",
            isOffered: true,
            priceRange: "$25/hr",
            imageUrl: nil
        ))
    }
}
