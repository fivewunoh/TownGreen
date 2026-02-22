//
//  NewsItem.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

enum NewsSource: String, CaseIterable {
    case valleyNews = "Valley News"
    case patch = "Patch"
    case pressEnterprise = "Press-Enterprise"
}

struct NewsItem: Identifiable {
    let id: UUID
    let title: String
    let link: String
    let description: String
    let pubDate: Date?
    let imageUrl: String?
    let source: NewsSource

    init(id: UUID = UUID(), title: String, link: String, description: String, pubDate: Date?, imageUrl: String?, source: NewsSource) {
        self.id = id
        self.title = title
        self.link = link
        self.description = description
        self.pubDate = pubDate
        self.imageUrl = imageUrl
        self.source = source
    }
}
