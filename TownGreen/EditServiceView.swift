//
//  EditServiceView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct EditServiceView: View {
    let service: Service
    var onSave: (Service) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isOffered: Bool
    @State private var title: String
    @State private var description: String
    @State private var categoryOption: ServiceCategoryOption
    @State private var location: String
    @State private var contactInfo: String
    @State private var priceRange: String
    @State private var selectedImage: UIImage?
    @State private var keepExistingImage: Bool
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(service: Service, onSave: @escaping (Service) -> Void) {
        self.service = service
        self.onSave = onSave
        _isOffered = State(initialValue: service.isOffered ?? true)
        _title = State(initialValue: service.title ?? "")
        _description = State(initialValue: service.description ?? "")
        _categoryOption = State(initialValue: ServiceCategoryOption(rawValue: service.category ?? "Other") ?? .other)
        _location = State(initialValue: service.location ?? "")
        _contactInfo = State(initialValue: service.contactInfo ?? "")
        _priceRange = State(initialValue: service.priceRange ?? "")
        _keepExistingImage = State(initialValue: service.imageUrl != nil)
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOffered ? "I am offering this service" : "I am looking for this service", isOn: $isOffered)
                    .tint(Color.primaryGreen)
            } header: {
                Text("Service type")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
            }

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
                } else if keepExistingImage, let urlString = service.imageUrl, let url = URL(string: urlString) {
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
                                .foregroundStyle(Color.textPrimary(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.townGreenCard(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                if (selectedImage != nil || (keepExistingImage && service.imageUrl != nil)) && selectedImage == nil {
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
                Picker("Category", selection: $categoryOption) {
                    ForEach(ServiceCategoryOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
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
                TextField("Contact info", text: $contactInfo)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                TextField("Price range (e.g. $20/hr, Free, Negotiable)", text: $priceRange)
                    .textContentType(.none)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
            } header: {
                Text("Service details")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
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
                        await saveService()
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
                .disabled(title.isEmpty || isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Edit Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Service")
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

    private func saveService() async {
        guard let _ = try? await SupabaseClient.shared.auth.session.user.id else {
            await MainActor.run {
                errorMessage = "You must be signed in to save."
            }
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var imageUrl: String?
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8),
           let userId = try? await SupabaseClient.shared.auth.session.user.id {
            let fileId = UUID().uuidString
            let path = "\(userId.uuidString)/\(fileId).jpg"
            do {
                try await SupabaseClient.shared.storage
                    .from("service-images")
                    .upload(path, data: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: false))
                let url = try SupabaseClient.shared.storage
                    .from("service-images")
                    .getPublicURL(path: path)
                imageUrl = url.absoluteString
            } catch {
                await MainActor.run {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                }
                return
            }
        } else if keepExistingImage {
            imageUrl = service.imageUrl
        }

        let request = UpdateServiceRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: categoryOption.rawValue,
            contactInfo: contactInfo.isEmpty ? nil : contactInfo.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
            isOffered: isOffered,
            priceRange: priceRange.isEmpty ? nil : priceRange.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl
        )

        do {
            try await SupabaseClient.shared
                .from("services")
                .update(request)
                .eq("id", value: service.id)
                .execute()

            let updated = Service(
                id: service.id,
                createdAt: service.createdAt,
                title: request.title,
                description: request.description,
                category: request.category,
                userId: service.userId,
                contactInfo: request.contactInfo,
                location: request.location,
                isOffered: request.isOffered,
                priceRange: request.priceRange,
                imageUrl: imageUrl
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
        EditServiceView(service: Service(
            id: 1,
            createdAt: nil,
            title: "Lawn mowing",
            description: "Weekly mowing.",
            category: "Lawn & Garden",
            userId: nil,
            contactInfo: nil,
            location: "Downtown",
            isOffered: true,
            priceRange: "$25/hr",
            imageUrl: nil
        )) { _ in }
    }
}
