//
//  Listing.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

struct Listing: Identifiable, Decodable {
    let id: Int
    let title: String?
    let description: String?
    let price: Double?
    let category: String?
    let location: String?
    let userId: UUID?
    let imageUrl: String?
    let isSold: Bool?
    let createdAt: Date?

    init(id: Int, title: String?, description: String?, price: Double?, category: String?, location: String?, userId: UUID?, imageUrl: String?, isSold: Bool?, createdAt: Date?) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.location = location
        self.userId = userId
        self.imageUrl = imageUrl
        self.isSold = isSold
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, location
        case userId = "user_id"
        case imageUrl = "image_url"
        case isSold = "is_sold"
        case createdAt = "created_at"
    }
}

struct CreateListingRequest: Encodable {
    let title: String
    let description: String
    let price: Double
    let category: String
    let location: String
    let userId: UUID
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, description, price, category, location
        case userId = "user_id"
        case imageUrl = "image_url"
    }
}

struct UpdateListingRequest: Encodable {
    let title: String
    let description: String
    let price: Double
    let category: String
    let location: String
    let imageUrl: String?
    let isSold: Bool?

    enum CodingKeys: String, CodingKey {
        case title, description, price, category, location
        case imageUrl = "image_url"
        case isSold = "is_sold"
    }
}

struct MarkAsSoldPayload: Encodable {
    let isSold: Bool
    enum CodingKeys: String, CodingKey {
        case isSold = "is_sold"
    }
}
