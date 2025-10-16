//
//  SearchResponse.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation

// MARK: - API Response DTOs

struct SearchResponse: Decodable, Sendable {
    let collection: SearchCollection
}

struct SearchCollection: Decodable, Sendable {
    let items: [SearchItem]
}

struct SearchItem: Decodable, Sendable {
    let href: String?
    let data: [SearchData]
    let links: [SearchLink]?  // May be nil - handle gracefully
}

struct SearchData: Decodable, Sendable {
    let nasaId: String
    let title: String
    let center: String?
    let description: String?
    let dateCreated: Date?
    let mediaType: String?
    let location: String?
    let photographer: String?
    let keywords: [String]?
}

struct SearchLink: Decodable, Sendable {
    let href: String
    let rel: String?
    let render: String?
    let width: Int?
    let height: Int?
    let size: Int?
}
