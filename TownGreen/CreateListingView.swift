//
//  CreateListingView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct CreateListingView: View {
    var onPosted: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var category = ""
    @State private var location = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isPosting = false
    @State private var errorMessage: String?

    private var priceValue: Double? {
        Double(priceText.trimmingCharacters(in: .whitespacesAndNewlines))
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
                        await postListing()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post Listing")
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
                .disabled(title.isEmpty || priceValue == nil || category.isEmpty || location.isEmpty || isPosting)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("New Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Listing")
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

    private func postListing() async {
        guard let price = priceValue else { return }
        guard let userId = try? await SupabaseClient.shared.auth.session.user.id else {
            await MainActor.run {
                errorMessage = "You must be signed in to post a listing."
            }
            return
        }

        isPosting = true
        errorMessage = nil
        defer { isPosting = false }

        var imageUrl: String?
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            let fileId = UUID().uuidString
            let path = "\(userId.uuidString)/\(fileId).jpg"
            do {
                try await SupabaseClient.shared.storage
                    .from("listing-images")
                    .upload(
                        path: path,
                        file: jpegData,
                        options: FileOptions(contentType: "image/jpeg", upsert: false)
                    )
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
        }

        let request = CreateListingRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            userId: userId,
            imageUrl: imageUrl
        )

        do {
            try await SupabaseClient.shared
                .from("listings")
                .insert(request)
                .execute()
            await onPosted()
            dismiss()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateListingView {}
    }
}
