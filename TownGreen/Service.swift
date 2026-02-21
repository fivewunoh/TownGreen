//
//  Service.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

struct Service: Identifiable, Decodable {
    let id: Int
    let createdAt: String?
    let title: String?
    let description: String?
    let category: String?
    let userId: String?
    let contactInfo: String?
    let location: String?
    let isOffered: Bool?
    let priceRange: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case description
        case category
        case userId = "user_id"
        case contactInfo = "contact_info"
        case location
        case isOffered = "is_offered"
        case priceRange = "price_range"
        case imageUrl = "image_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        contactInfo = try c.decodeIfPresent(String.self, forKey: .contactInfo)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        isOffered = try c.decodeIfPresent(Bool.self, forKey: .isOffered)
        priceRange = try c.decodeIfPresent(String.self, forKey: .priceRange)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
    }

    init(id: Int, createdAt: String?, title: String?, description: String?, category: String?, userId: String?, contactInfo: String?, location: String?, isOffered: Bool?, priceRange: String?, imageUrl: String?) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.description = description
        self.category = category
        self.userId = userId
        self.contactInfo = contactInfo
        self.location = location
        self.isOffered = isOffered
        self.priceRange = priceRange
        self.imageUrl = imageUrl
    }
}

// MARK: - Service category options

enum ServiceCategoryOption: String, CaseIterable {
    case lawnAndGarden = "Lawn & Garden"
    case cleaning = "Cleaning"
    case handyman = "Handyman"
    case tutoring = "Tutoring"
    case petCare = "Pet Care"
    case beauty = "Beauty"
    case techHelp = "Tech Help"
    case moving = "Moving"
    case cooking = "Cooking"
    case other = "Other"
}

// MARK: - Create / Update requests

struct CreateServiceRequest: Encodable {
    let title: String
    let description: String
    let category: String?
    let userId: String
    let contactInfo: String?
    let location: String?
    let isOffered: Bool
    let priceRange: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, description, category, location
        case userId = "user_id"
        case contactInfo = "contact_info"
        case isOffered = "is_offered"
        case priceRange = "price_range"
        case imageUrl = "image_url"
    }
}

struct UpdateServiceRequest: Encodable {
    let title: String
    let description: String
    let category: String?
    let contactInfo: String?
    let location: String?
    let isOffered: Bool
    let priceRange: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, description, category, location
        case contactInfo = "contact_info"
        case isOffered = "is_offered"
        case priceRange = "price_range"
        case imageUrl = "image_url"
    }
}
