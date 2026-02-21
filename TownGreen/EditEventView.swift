//
//  EditEventView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct EditEventView: View {
    let event: Event
    var onSave: (Event) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String
    @State private var description: String
    @State private var eventDate: Date
    @State private var location: String
    @State private var address: String
    @State private var eventTypeOption: EventTypeOption
    @State private var isFree: Bool
    @State private var selectedImage: UIImage?
    @State private var keepExistingImage: Bool
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(event: Event, onSave: @escaping (Event) -> Void) {
        self.event = event
        self.onSave = onSave
        _title = State(initialValue: event.title ?? "")
        _description = State(initialValue: event.description ?? "")
        _location = State(initialValue: event.location ?? "")
        _address = State(initialValue: event.address ?? "")
        _eventTypeOption = State(initialValue: EventTypeOption(rawValue: event.eventType ?? "Community") ?? .community)
        _isFree = State(initialValue: event.isFree ?? true)
        _keepExistingImage = State(initialValue: event.imageUrl != nil)
        let parsed = Self.parseEventDate(event.eventDate)
        _eventDate = State(initialValue: parsed ?? Date())
    }

    private static func parseEventDate(_ raw: String?) -> Date? {
        TownGreenDateFormatter.parseISO8601(raw)
    }

    var body: some View {
        Form {
            Section {
                if let image = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button {
                            selectedImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                } else if keepExistingImage, let urlString = event.imageUrl, let url = URL(string: urlString) {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Color.townGreenCard(for: colorScheme)
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.primaryGreen.opacity(0.6))
                            }
                        }
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button {
                            keepExistingImage = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                } else {
                    Button {
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.primaryGreen)
                            Text("Add photo")
                                .font(Font.TownGreenFonts.caption)
                                .foregroundStyle(Color.primaryGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.townGreenCard(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                if (selectedImage != nil || (keepExistingImage && event.imageUrl != nil)) && selectedImage == nil {
                    Button("Change photo") {
                        showImagePicker = true
                    }
                    .font(Font.TownGreenFonts.caption)
                    .foregroundStyle(Color.primaryGreen)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            Section {
                TextField("Title", text: $title)
                    .textContentType(.none)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                DatePicker("Date & time", selection: $eventDate)
                    .datePickerStyle(.compact)
                    .tint(Color.primaryGreen)
                TextField("Location", text: $location)
                    .textContentType(.addressCityAndState)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                TextField("Address (optional)", text: $address)
                    .textContentType(.fullStreetAddress)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                Picker("Event type", selection: $eventTypeOption) {
                    ForEach(EventTypeOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.primaryGreen)
                Toggle("Free event", isOn: $isFree)
                    .tint(Color.primaryGreen)
            } header: {
                Text("Event details")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.primaryGreen)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await saveEvent()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .font(Font.TownGreenFonts.button)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.isEmpty || location.isEmpty || isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Event")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .font(Font.TownGreenFonts.button)
                .foregroundStyle(Color.primaryGreen)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func saveEvent() async {
        guard let _ = try? await SupabaseClient.shared.auth.session.user.id else {
            await MainActor.run {
                errorMessage = "You must be signed in to save."
            }
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let eventDateString = isoFormatter.string(from: eventDate)

        var imageUrl: String?
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8),
           let userId = try? await SupabaseClient.shared.auth.session.user.id {
            let fileId = UUID().uuidString
            let path = "\(userId.uuidString)/\(fileId).jpg"
            do {
                try await SupabaseClient.shared.storage
                    .from("event-images")
                    .upload(path, data: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: false))
                let url = try SupabaseClient.shared.storage
                    .from("event-images")
                    .getPublicURL(path: path)
                imageUrl = url.absoluteString
            } catch {
                await MainActor.run {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                }
                return
            }
        } else if keepExistingImage {
            imageUrl = event.imageUrl
        }

        let request = UpdateEventRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            eventDate: eventDateString,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines),
            eventType: eventTypeOption.rawValue,
            imageUrl: imageUrl,
            isFree: isFree
        )

        do {
            try await SupabaseClient.shared
                .from("events")
                .update(request)
                .eq("id", value: event.id)
                .execute()

            let updated = Event(
                id: event.id,
                createdAt: event.createdAt,
                title: request.title,
                description: request.description,
                eventDate: request.eventDate,
                location: request.location,
                address: request.address,
                userId: event.userId,
                eventType: request.eventType,
                imageUrl: imageUrl,
                isFree: request.isFree
            )
            await MainActor.run {
                onSave(updated)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditEventView(event: Event(
            id: 1,
            createdAt: nil,
            title: "Community Cleanup",
            description: "Join us.",
            eventDate: "2026-03-15T14:00:00Z",
            location: "Main Park",
            address: nil,
            userId: nil,
            eventType: "Community",
            imageUrl: nil,
            isFree: true
        )) { _ in }
    }
}
