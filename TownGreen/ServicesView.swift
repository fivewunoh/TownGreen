//
//  ServicesView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

enum ServiceFilterMode: String, CaseIterable {
    case offered = "Offered"
    case wanted = "Wanted"
}

struct ServicesView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var services: [Service] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateService = false
    @State private var filterMode: ServiceFilterMode = .offered

    private var filteredServices: [Service] {
        let offered = filterMode == .offered
        return services.filter { ($0.isOffered ?? true) == offered }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && services.isEmpty {
                    ProgressView("Loading services…")
                        .font(Font.TownGreenFonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to load services",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            Picker("", selection: $filterMode) {
                                ForEach(ServiceFilterMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            ForEach(filteredServices) { service in
                                NavigationLink {
                                    ServiceDetailView(service: service)
                                } label: {
                                    ServiceCard(service: service, colorScheme: colorScheme)
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
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Services")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateService = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.primaryGreen)
                    }
                }
            }
            .task {
                await fetchServices()
            }
            .onAppear {
                Task { await fetchServices() }
            }
            .refreshable {
                await fetchServices()
            }
            .sheet(isPresented: $showCreateService) {
                NavigationStack {
                    CreateServiceView {
                        showCreateService = false
                        Task { await fetchServices() }
                    }
                }
            }
        }
    }

    private func fetchServices() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched: [Service] = try await SupabaseClient.shared
                .from("services")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            await MainActor.run {
                self.services = fetched
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct ServiceCard: View {
    let service: Service
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(service.title ?? "Untitled")
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if let category = service.category, !category.isEmpty {
                        Text(category)
                            .font(Font.TownGreenFonts.caption)
                            .foregroundStyle(Color.darkGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.lightGreen)
                            .clipShape(Capsule())
                    }
                    if let price = service.priceRange, !price.isEmpty {
                        Text(price)
                            .font(Font.TownGreenFonts.caption)
                            .foregroundStyle(Color.primaryGreen)
                    }
                }
                if let location = service.location, !location.isEmpty {
                    Text(location)
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(Color.darkGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let urlString = service.imageUrl, let url = URL(string: urlString) {
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
            Image(systemName: "wrench.and.screwdriver")
                .font(.title2)
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }
}

#Preview {
    ServicesView()
}
