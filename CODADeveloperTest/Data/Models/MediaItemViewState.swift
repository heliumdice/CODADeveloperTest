//
//  MediaItemViewState.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation

/// View state representation of a media item for UI display
struct MediaItemViewState: Identifiable, Hashable {
    let id: String
    let nasaID: String
    let title: String
    let center: String?
    let description: String?
    let assetCount: Int
    let thumbnailURL: URL?
    let dateCreated: Date?

    /// Creates view state from Core Data MediaItem entity
    init(from mediaItem: MediaItem) {
        self.id = mediaItem.nasaID ?? UUID().uuidString
        self.nasaID = mediaItem.nasaID ?? ""
        self.title = mediaItem.title ?? "Unknown"
        self.center = mediaItem.center
        self.description = mediaItem.itemDescription
        self.dateCreated = mediaItem.dateCreated

        // Count related links
        self.assetCount = (mediaItem.links as? Set<MediaLink>)?.count ?? 0

        // Find preview/thumbnail URL from links
        if let links = mediaItem.links as? Set<MediaLink> {
            // Prefer "preview" rel type, otherwise take first link
            let previewLink = links.first { $0.rel == "preview" } ?? links.first
            self.thumbnailURL = previewLink?.href.flatMap { URL(string: $0) }
        } else {
            self.thumbnailURL = nil
        }
    }

    /// Direct initializer for creating view states (used by mock)
    private init(
        id: String,
        nasaID: String,
        title: String,
        center: String?,
        description: String?,
        assetCount: Int,
        thumbnailURL: URL?,
        dateCreated: Date?
    ) {
        self.id = id
        self.nasaID = nasaID
        self.title = title
        self.center = center
        self.description = description
        self.assetCount = assetCount
        self.thumbnailURL = thumbnailURL
        self.dateCreated = dateCreated
    }

    // MARK: - Mock for Previews

    /// Creates a mock MediaItemViewState for SwiftUI previews
    static func mock(
        id: String = UUID().uuidString,
        nasaID: String = "PIA12345",
        title: String = "Mars Rover Discovery",
        center: String? = "JPL",
        description: String? = "A stunning view of the Martian surface captured by the Curiosity rover.",
        assetCount: Int = 5,
        thumbnailURL: URL? = URL(string: "https://images-assets.nasa.gov/image/PIA12345/PIA12345~thumb.jpg"),
        dateCreated: Date? = Date()
    ) -> MediaItemViewState {
        MediaItemViewState(
            id: id,
            nasaID: nasaID,
            title: title,
            center: center,
            description: description,
            assetCount: assetCount,
            thumbnailURL: thumbnailURL,
            dateCreated: dateCreated
        )
    }
}
