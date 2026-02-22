//
//  EventDetailView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct EventDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var event: Event
    @State private var currentUserId: String?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    private var isOwner: Bool {
        guard let current = currentUserId, let eventUserId = event.userId else { return false }
        return current.lowercased() == eventUserId.lowercased()
    }

    init(event: Event) {
        _event = State(initialValue: event)
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
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Event")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
        }
        .task {
            await loadCurrentUser()
        }
        .alert("Delete event?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteEvent() }
            }
        } message: {
            Text("Are you sure you want to delete this event?")
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditEventView(event: event) { updated in
                    event = updated
                    showEditSheet = false
                }
            }
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let urlString = event.imageUrl, let url = URL(string: urlString) {
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
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(event.title ?? "Untitled")
                .font(Font.TownGreenFonts.title)
                .foregroundStyle(Color.textPrimary(for: colorScheme))

            Text(TownGreenDateFormatter.formatEventDateTimeFromUTC(iso8601: event.eventDate))
                .font(Font.TownGreenFonts.body)
                .foregroundStyle(Color.textPrimary(for: colorScheme))

            if let createdAt = event.createdAt, !createdAt.isEmpty {
                DetailRow(label: "Posted", value: TownGreenDateFormatter.formatCreatedAt(iso8601: createdAt))
            }

            if let location = event.location, !location.isEmpty {
                DetailRow(label: "Location", value: location)
            }
            if let address = event.address, !address.isEmpty {
                DetailRow(label: "Address", value: address)
            }

            HStack(spacing: 8) {
                if let type = event.eventType, !type.isEmpty {
                    Text(type)
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.darkGreen)
                        .clipShape(Capsule())
                }
                Text((event.isFree ?? true) ? "Free" : "Paid")
                    .font(Font.TownGreenFonts.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.darkGreen)
                    .clipShape(Capsule())
            }

            if let description = event.description, !description.isEmpty {
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
                    Text("Edit Event")
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

                if currentUserId == event.userId {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Event")
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

    // RLS reminder: Supabase events table should only allow DELETE when auth.uid()::text = user_id.
    private func deleteEvent() async {
        do {
            try await SupabaseClient.shared
                .from("events")
                .delete()
                .eq("id", value: event.id)
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
        EventDetailView(event: Event(
            id: 1,
            createdAt: nil,
            title: "Community Cleanup",
            description: "Join us for a neighborhood cleanup.",
            eventDate: "2026-03-15T14:00:00Z",
            location: "Main Park",
            address: "123 Green St",
            userId: nil,
            eventType: "Community",
            imageUrl: nil,
            isFree: true
        ))
    }
}
