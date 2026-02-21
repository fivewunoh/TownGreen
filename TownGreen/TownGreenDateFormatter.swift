//
//  TownGreenDateFormatter.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

/// Reusable date formatting for TownGreen: created_at and event_date styles.
enum TownGreenDateFormatter {

    /// US style: e.g. "2/21/2025 at 3:45 PM"
    static let createdAt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d/yyyy 'at' h:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    /// Event date/time: e.g. "Sat, Mar 15 · 2:00 PM"
    static let eventDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    /// Parse ISO8601 string (with or without fractional seconds) to Date.
    /// Uses TimeZone.current so parsing matches event_date strings saved with TimeZone.current.
    static func parseISO8601(_ raw: String?) -> Date? {
        guard let raw = raw else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        withFraction.timeZone = TimeZone.current
        if let d = withFraction.date(from: raw) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        plain.timeZone = TimeZone.current
        return plain.date(from: raw)
    }

    /// Parse event_date from Supabase as UTC (e.g. "2026-02-22T13:23:00" with no suffix = UTC).
    static func parseISO8601AsUTC(_ raw: String?) -> Date? {
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

    /// Format a Date for created_at display (listings, events, services).
    static func formatCreatedAt(from date: Date?) -> String {
        guard let date = date else { return "—" }
        return createdAt.string(from: date)
    }

    /// Format an ISO8601 string for created_at display.
    static func formatCreatedAt(iso8601 raw: String?) -> String {
        guard let date = parseISO8601(raw) else { return "—" }
        return createdAt.string(from: date)
    }

    /// Format an ISO8601 string for event_date display (friendly date/time).
    static func formatEventDateTime(iso8601 raw: String?) -> String {
        guard let date = parseISO8601(raw) else { return "—" }
        return eventDateTime.string(from: date)
    }

    /// Format event_date from Supabase (stored as UTC, no suffix) for display in local time.
    static func formatEventDateTimeFromUTC(iso8601 raw: String?) -> String {
        guard let date = parseISO8601AsUTC(raw) else { return "—" }
        return eventDateTime.string(from: date)
    }
}
