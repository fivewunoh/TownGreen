//
//  NewsView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

private enum FeedConfig {
    static let valleyNews = (url: URL(string: "https://myvalleynews.com/feed/")!, source: NewsSource.valleyNews)
    static let patch = (url: URL(string: "https://patch.com/california/murrieta/rss.xml")!, source: NewsSource.patch)
    static let pressEnterprise = (url: URL(string: "https://www.pe.com/location/california/riverside-county/murrieta/feed/")!, source: NewsSource.pressEnterprise)
}

struct NewsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var items: [NewsItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var safariURL: URL?
    @State private var showSafari = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && items.isEmpty {
                    ProgressView("Loading news…")
                        .font(Font.TownGreenFonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage, items.isEmpty {
                    VStack(spacing: 16) {
                        Text(error)
                            .font(Font.TownGreenFonts.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { await fetchAllFeeds() }
                        }
                        .font(Font.TownGreenFonts.button)
                        .foregroundStyle(Color.primaryGreen)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                Button {
                                    if let url = URL(string: item.link) {
                                        safariURL = url
                                        showSafari = true
                                    }
                                } label: {
                                    NewsCard(item: item, colorScheme: colorScheme)
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
            .navigationTitle("Local News")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Local News")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
            }
            .task {
                await fetchAllFeeds()
            }
            .refreshable {
                await fetchAllFeeds()
            }
            .sheet(isPresented: $showSafari, onDismiss: { safariURL = nil }) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
        }
    }

    private func fetchAllFeeds() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let valley = fetchFeedSafe(url: FeedConfig.valleyNews.url, source: FeedConfig.valleyNews.source)
        async let patch = fetchFeedSafe(url: FeedConfig.patch.url, source: FeedConfig.patch.source)
        async let pe = fetchFeedSafe(url: FeedConfig.pressEnterprise.url, source: FeedConfig.pressEnterprise.source)

        let results = await [valley, patch, pe]
        let merged = results.flatMap { $0 }
        let sorted = merged.sorted { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }
        await MainActor.run {
            self.items = sorted
            if sorted.isEmpty {
                self.errorMessage = results.allSatisfy({ $0.isEmpty }) ? "No articles could be loaded. Check your connection and try again." : nil
            } else {
                self.errorMessage = nil
            }
        }
    }

    private func fetchFeedSafe(url: URL, source: NewsSource) async -> [NewsItem] {
        do {
            return try await fetchFeed(url: url, source: source)
        } catch {
            return []
        }
    }

    private func fetchFeed(url: URL, source: NewsSource) async throws -> [NewsItem] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = RSSFeedParser(source: source)
        return parser.parse(data: data)
    }
}

struct NewsCard: View {
    let item: NewsItem
    let colorScheme: ColorScheme

    private var sourceBadgeColor: Color {
        switch item.source {
        case .valleyNews: return Color.primaryGreen
        case .patch: return Color(hex: "6B4E71")
        case .pressEnterprise: return Color.darkGreen
        }
    }

    private var formattedDate: String {
        guard let date = item.pubDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "M/d/yyyy"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(Font.TownGreenFonts.title)
                    .foregroundStyle(Color.primaryGreen)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(item.source.rawValue)
                    .font(Font.TownGreenFonts.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sourceBadgeColor)
                    .clipShape(Capsule())
                if !formattedDate.isEmpty {
                    Text(formattedDate)
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(Color.darkGreen)
                }
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(Font.TownGreenFonts.body)
                        .fontWeight(.light)
                        .foregroundStyle(Color.darkGreen)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let urlString = item.imageUrl, let url = URL(string: urlString) {
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
                .frame(width: 80, height: 80)
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
            Image(systemName: "newspaper")
                .font(.title2)
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }
}

#Preview {
    NewsView()
}
