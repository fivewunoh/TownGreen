//
//  EditProfileView.swift
//  TownGreen
//

import SwiftUI
import Supabase

enum NeighborhoodOption: String, CaseIterable {
    case frenchValley = "French Valley"
    case winchester = "Winchester"
    case murrieta = "Murrieta"
    case temecula = "Temecula"
    case other = "Other"
}

struct EditProfileView: View {
    let profile: Profile?
    let userId: String
    var onSave: (Profile?) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileManager: ProfileManager

    @State private var fullName: String = ""
    @State private var neighborhoodOption: NeighborhoodOption = .other
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Button {
                    showImagePicker = true
                } label: {
                    HStack(spacing: 16) {
                        avatarPreview
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Change photo")
                                .font(Font.TownGreenFonts.button)
                                .foregroundStyle(Color.primaryGreen)
                            Text("Tap to choose from library")
                                .font(Font.TownGreenFonts.caption)
                                .foregroundStyle(Color.textPrimary(for: colorScheme).opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            } header: {
                Text("Photo")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
            }
            .listRowBackground(Color.clear)

            Section {
                TextField("Display name", text: $fullName)
                    .textContentType(.name)
                    .padding(12)
                    .background(Color.townGreenCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lightGreen, lineWidth: 1)
                    )
                Picker("Neighborhood", selection: $neighborhoodOption) {
                    ForEach(NeighborhoodOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Details")
                    .font(Font.TownGreenFonts.sectionHeader)
                    .foregroundStyle(Color.textPrimary(for: colorScheme))
            }
            .listRowBackground(Color.clear)

            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(Font.TownGreenFonts.body)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await saveProfile() }
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
                    .background(Color.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSaving)
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(Color.townGreenBackground(for: colorScheme))
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
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
        .onAppear {
            fullName = profile?.fullName ?? profile?.displayName ?? ""
            neighborhoodOption = NeighborhoodOption(rawValue: profile?.neighborhood ?? "") ?? .other
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = profile?.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        editAvatarPlaceholder
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        editAvatarPlaceholder
                    @unknown default:
                        editAvatarPlaceholder
                    }
                }
            } else {
                editAvatarPlaceholder
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
    }

    private var editAvatarPlaceholder: some View {
        ZStack {
            Color.lightGreen.opacity(0.3)
            Image(systemName: "person.fill")
                .font(.title2)
                .foregroundStyle(Color.primaryGreen)
        }
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var avatarUrl: String? = profile?.avatarUrl
        if let image = selectedImage, let jpegData = image.jpegData(compressionQuality: 0.8) {
            let fileId = UUID().uuidString
            let path = "\(userId)/\(fileId).jpg"
            do {
                try await SupabaseClient.shared.storage
                    .from("avatars")
                    .upload(path, data: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: true))
                let url = try SupabaseClient.shared.storage
                    .from("avatars")
                    .getPublicURL(path: path)
                avatarUrl = url.absoluteString
            } catch {
                await MainActor.run {
                    errorMessage = "Photo upload failed: \(error.localizedDescription)"
                }
                return
            }
        }

        await profileManager.updateProfile(
            userId: userId,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: nil,
            neighborhood: neighborhoodOption.rawValue,
            avatarUrl: avatarUrl
        )

        if profileManager.errorMessage != nil {
            await MainActor.run {
                errorMessage = profileManager.errorMessage
            }
            return
        }

        let updated = await profileManager.fetchProfile(userId: userId)
        await MainActor.run {
            onSave(updated)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(profile: nil, userId: "00000000-0000-0000-0000-000000000000") { _ in }
            .environmentObject(ProfileManager())
    }
}
