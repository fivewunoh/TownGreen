//
//  RSSFeedParser.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation

final class RSSFeedParser: NSObject, XMLParserDelegate {
    private var items: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageUrl: String?
    private let source: NewsSource

    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, d MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd HH:mm:ss Z",
            "d MMM yyyy HH:mm:ss Z",
            "MMM d, yyyy h:mm a"
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }
    }()

    init(source: NewsSource) {
        self.source = source
    }

    func parse(data: Data) -> [NewsItem] {
        items = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    private func parsedDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    private func stripHTML(from string: String) -> String {
        string
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageUrl = nil
        }
        if elementName == "enclosure", let url = attributeDict["url"], let type = attributeDict["type"], type.hasPrefix("image") {
            currentImageUrl = url
        }
        if elementName == "media:content", let url = attributeDict["url"] {
            currentImageUrl = url
        }
        if elementName == "media:thumbnail", let url = attributeDict["url"] {
            currentImageUrl = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        appendToCurrentElement(string)
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            appendToCurrentElement(string)
        }
    }

    private func appendToCurrentElement(_ string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let title = stripHTML(from: currentTitle).trimmingCharacters(in: .whitespacesAndNewlines)
            let link = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let desc = stripHTML(from: currentDescription).trimmingCharacters(in: .whitespacesAndNewlines)
            let date = parsedDate(from: currentPubDate)
            if !title.isEmpty && !link.isEmpty {
                items.append(NewsItem(
                    title: title,
                    link: link,
                    description: desc,
                    pubDate: date,
                    imageUrl: currentImageUrl,
                    source: source
                ))
            }
        }
        currentElement = ""
    }
}
