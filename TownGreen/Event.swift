//
//  Event.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

struct Event: Identifiable, Decodable {
    let id: Int
    let createdAt: String?
    let title: String?
    let description: String?
    let eventDate: String?
    let location: String?
    let address: String?
    let userId: String?
    let eventType: String?
    let imageUrl: String?
    let isFree: Bool?

    /// Maps to Supabase columns (snake_case); e.g. event_date in DB → eventDate here.
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case description
        case eventDate = "event_date"
        case location
        case address
        case userId = "user_id"
        case eventType = "event_type"
        case imageUrl = "image_url"
        case isFree = "is_free"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        eventDate = try c.decodeIfPresent(String.self, forKey: .eventDate)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        eventType = try c.decodeIfPresent(String.self, forKey: .eventType)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        isFree = try c.decodeIfPresent(Bool.self, forKey: .isFree)
    }

    init(id: Int, createdAt: String?, title: String?, description: String?, eventDate: String?, location: String?, address: String?, userId: String?, eventType: String?, imageUrl: String?, isFree: Bool?) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.description = description
        self.eventDate = eventDate
        self.location = location
        self.address = address
        self.userId = userId
        self.eventType = eventType
        self.imageUrl = imageUrl
        self.isFree = isFree
    }
}

// MARK: - Event type options

enum EventTypeOption: String, CaseIterable {
    case community = "Community"
    case foodAndDrink = "Food & Drink"
    case music = "Music"
    case sports = "Sports"
    case arts = "Arts"
    case family = "Family"
    case other = "Other"
}

// MARK: - Create / Update requests

struct CreateEventRequest: Encodable {
    let title: String
    let description: String
    let eventDate: String
    let location: String
    let address: String?
    let userId: String
    let eventType: String?
    let imageUrl: String?
    let isFree: Bool

    enum CodingKeys: String, CodingKey {
        case title, description, location, address
        case eventDate = "event_date"
        case userId = "user_id"
        case eventType = "event_type"
        case imageUrl = "image_url"
        case isFree = "is_free"
    }
}

struct UpdateEventRequest: Encodable {
    let title: String
    let description: String
    let eventDate: String
    let location: String
    let address: String?
    let eventType: String?
    let imageUrl: String?
    let isFree: Bool

    enum CodingKeys: String, CodingKey {
        case title, description, location, address
        case eventDate = "event_date"
        case eventType = "event_type"
        case imageUrl = "image_url"
        case isFree = "is_free"
    }
}
