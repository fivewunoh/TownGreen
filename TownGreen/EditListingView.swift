//
//  EditListingView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct EditListingView: View {
    let listing: Listing
    var onSave: (Listing) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String
    @State private var description: String
    @State private var priceText: String
    @State private var category: String
    @State private var location: String
    @State private var selectedImage: UIImage?
    @State private var keepExistingImage: Bool
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var priceValue: Double? {
        Double(priceText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    init(listing: Listing, onSave: @escaping (Listing) -> Void) {
        self.listing = listing
        self.onSave = onSave
        _title = State(initialValue: listing.title ?? "")
        _description = State(initialValue: listing.description ?? "")
        _priceText = State(initialValue: listing.price.map { String(format: "%.2f", $0) } ?? "")
        _category = State(initialValue: listing.category ?? "")
        _location = State(initialValue: listing.location ?? "")
        _keepExistingImage = State(initialValue: listing.imageUrl != nil)
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
                } else if keepExistingImage, let urlString = listing.imageUrl, let url = URL(string: urlString) {
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
                if (selectedImage != nil || (keepExistingImage && listing.imageUrl != nil)) && selectedImage == nil {
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
                TextField("Price", text: $priceText)
                    .keyboardType(.decimalPad)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                TextField("Category", text: $category)
                    .textContentType(.none)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                TextField("Location", text: $location)
                    .textContentType(.addressCityAndState)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
            } header: {
                Text("Listing details")
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
                        await saveListing()
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
                .disabled(title.isEmpty || priceValue == nil || category.isEmpty || location.isEmpty || isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Edit Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Listing")
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

    private func saveListing() async {
        guard let price = priceValue else { return }
        guard let userId = try? await SupabaseClient.shared.auth.session.user.id else {
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
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            let fileId = UUID().uuidString
            let path = "\(userId.uuidString)/\(fileId).jpg"
            do {
                try await SupabaseClient.shared.storage
                    .from("listing-images")
                    .upload(path, data: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: false))
                let url = try SupabaseClient.shared.storage
                    .from("listing-images")
                    .getPublicURL(path: path)
                imageUrl = url.absoluteString
            } catch {
                await MainActor.run {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                }
                return
            }
        } else if keepExistingImage {
            imageUrl = listing.imageUrl
        }

        let request = UpdateListingRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl,
            isSold: listing.isSold
        )

        do {
            try await SupabaseClient.shared
                .from("listings")
                .update(request)
                .eq("id", value: listing.id)
                .execute()

            let updated = Listing(
                id: listing.id,
                title: request.title,
                description: request.description,
                price: request.price,
                category: request.category,
                location: request.location,
                userId: listing.userId,
                imageUrl: imageUrl,
                isSold: listing.isSold,
                createdAt: listing.createdAt
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
        EditListingView(listing: Listing(
            id: 1,
            title: "Vintage Bike",
            description: "Great condition.",
            price: 150,
            category: "Sports",
            location: "Downtown",
            userId: UUID(),
            imageUrl: nil,
            isSold: nil,
            createdAt: nil
        )) { _ in }
    }
}
