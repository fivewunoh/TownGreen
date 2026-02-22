//
//  Profile.swift
//  TownGreen
//

import Foundation

struct Profile: Identifiable, Decodable, Encodable {
    let id: Int?
    let userId: String?
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let neighborhood: String?
    let isVerified: Bool?
    let createdAt: Date?

    var displayName: String {
        let name = fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = name, !name.isEmpty { return name }
        if let username = username, !username.isEmpty { return username }
        return "Member"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case neighborhood
        case isVerified = "is_verified"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        username = try c.decodeIfPresent(String.self, forKey: .username)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
        neighborhood = try c.decodeIfPresent(String.self, forKey: .neighborhood)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
        if let dateStr = try c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = ISO8601DateFormatter().date(from: dateStr)
                ?? ISO8601DateFormatter().date(from: dateStr.replacingOccurrences(of: "Z", with: "+00:00"))
        } else {
            createdAt = nil
        }
    }

    init(id: Int?, userId: String?, username: String?, fullName: String?, avatarUrl: String?, neighborhood: String?, isVerified: Bool?, createdAt: Date?) {
        self.id = id
        self.userId = userId
        self.username = username
        self.fullName = fullName
        self.avatarUrl = avatarUrl
        self.neighborhood = neighborhood
        self.isVerified = isVerified
        self.createdAt = createdAt
    }
}

/// Payload for insert/update (omit id for insert; use for update)
struct UpdateProfileRequest: Encodable {
    let userId: String?
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let neighborhood: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case neighborhood
    }
}
