//
//  CreateServiceView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct CreateServiceView: View {
    var onPosted: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isOffered = true
    @State private var title = ""
    @State private var description = ""
    @State private var categoryOption: ServiceCategoryOption = .other
    @State private var location = ""
    @State private var contactInfo = ""
    @State private var priceRange = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isPosting = false
    @State private var errorMessage: String?

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
                        await postService()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post")
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
                .disabled(title.isEmpty || isPosting)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("New Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Service")
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

    private func postService() async {
        guard let userId = try? await SupabaseClient.shared.auth.session.user.id else {
            await MainActor.run {
                errorMessage = "You must be signed in to post a service."
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
        }

        let request = CreateServiceRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: categoryOption.rawValue,
            userId: userId.uuidString,
            contactInfo: contactInfo.isEmpty ? nil : contactInfo.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
            isOffered: isOffered,
            priceRange: priceRange.isEmpty ? nil : priceRange.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl
        )

        do {
            try await SupabaseClient.shared
                .from("services")
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
        CreateServiceView {}
    }
}
