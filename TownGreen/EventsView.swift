//
//  EventsView.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI
import Supabase

struct EventsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authManager: AuthManager

    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateEvent = false
    @State private var showSettings = false

    /// Sorted by event_date (soonest first). No extra filter here — past-event filtering is done in fetchEvents() when filterPastEvents is true.
    private var sortedEvents: [Event] {
        events.sorted { (eventDate(for: $0) ?? .distantPast) < (eventDate(for: $1) ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && events.isEmpty {
                    ProgressView("Loading events…")
                        .font(Font.TownGreenFonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to load events",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventCard(event: event, colorScheme: colorScheme)
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
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Events")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(Color.primaryGreen)
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color.primaryGreen)
                        }
                        Button {
                            showCreateEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.primaryGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .task {
                print("[EventsView] .task started — calling fetchEvents()")
                await fetchEvents()
            }
            .onAppear {
                print("[EventsView] .onAppear fired — calling fetchEvents()")
                Task { await fetchEvents() }
            }
            .refreshable {
                await fetchEvents()
            }
            .sheet(isPresented: $showCreateEvent) {
                NavigationStack {
                    CreateEventView {
                        showCreateEvent = false
                        Task { await fetchEvents() }
                    }
                }
            }
        }
    }

    private func fetchEvents() async {
        print("[EventsView] fetchEvents() called")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched: [Event] = try await SupabaseClient.shared
                .from("events")
                .select()
                .order("event_date", ascending: true)
                .execute()
                .value
            print("[EventsView] Supabase returned \(fetched.count) events (before any filter)")
            for (index, event) in fetched.enumerated() {
                print("[EventsView]   [\(index)] title: \(event.title ?? "nil"), event_date: \(event.eventDate ?? "nil")")
            }
            await MainActor.run {
                let nowUTC = Date()
                self.events = fetched.filter { event in
                    guard let utcDate = parseEventDateAsUTC(event.eventDate) else { return true }
                    return utcDate >= nowUTC
                }
                print("[EventsView] @State events updated on MainActor, count: \(self.events.count)")
            }
        } catch {
            print("[EventsView] Fetch error (full): \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("[EventsView] Decode keyNotFound: key=\(key.stringValue), path=\(context.codingPath.map(\.stringValue).joined(separator: ".")), \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("[EventsView] Decode typeMismatch: expected \(type), path=\(context.codingPath.map(\.stringValue).joined(separator: ".")), \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("[EventsView] Decode valueNotFound: \(type), path=\(context.codingPath.map(\.stringValue).joined(separator: ".")), \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("[EventsView] Decode dataCorrupted: \(context.debugDescription)")
                @unknown default:
                    print("[EventsView] Decode error: \(decodingError)")
                }
            }
            await MainActor.run {
                self.errorMessage = String(describing: error)
            }
        }
    }

    /// Parse event_date string as UTC for filter/sort. Supabase stores in UTC; use UTC so comparison with Date() is correct.
    private func parseEventDateAsUTC(_ raw: String?) -> Date? {
        guard let raw = raw else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        withFraction.timeZone = TimeZone(secondsFromGMT: 0)
        if let d = withFraction.date(from: raw) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        plain.timeZone = TimeZone(secondsFromGMT: 0)
        return plain.date(from: raw)
    }

    private func eventDate(for event: Event) -> Date? {
        parseEventDateAsUTC(event.eventDate)
    }
}

struct EventCard: View {
    let event: Event
    let colorScheme: ColorScheme

    /// Countdown when event is within 24 hours of now. Parse event_date as UTC (e.g. "2026-02-22T13:23:00"); hours rounded up.
    private var countdownText: String? {
        guard let date = TownGreenDateFormatter.parseISO8601AsUTC(event.eventDate) else { return nil }
        let interval = date.timeIntervalSinceNow
        guard interval > 0, interval <= 24 * 3600 else { return nil }
        let hours = Int(ceil(interval / 3600))
        return hours <= 1 ? "in 1 hr" : "in \(hours) hrs"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(event.title ?? "Untitled")
                        .font(Font.TownGreenFonts.title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let countdown = countdownText {
                        Text(countdown)
                            .font(Font.TownGreenFonts.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                Text(TownGreenDateFormatter.formatEventDateTimeFromUTC(iso8601: event.eventDate))
                    .font(Font.TownGreenFonts.caption)
                    .foregroundStyle(Color.darkGreen)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle(Color.darkGreen)
                }
                HStack(spacing: 8) {
                    if let type = event.eventType, !type.isEmpty {
                        Text(type)
                            .font(Font.TownGreenFonts.caption)
                            .foregroundStyle(Color.darkGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.lightGreen)
                            .clipShape(Capsule())
                    }
                    Text((event.isFree ?? true) ? "Free" : "Paid")
                        .font(Font.TownGreenFonts.caption)
                        .foregroundStyle((event.isFree ?? true) ? Color.primaryGreen : Color.darkGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let urlString = event.imageUrl, let url = URL(string: urlString) {
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
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(Color.primaryGreen.opacity(0.6))
        }
    }

}

#Preview {
    EventsView()
}
