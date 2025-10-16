//
//  MediaItemViewState.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation

/// View state representation of a media link/asset
struct MediaLinkViewState: Identifiable, Hashable {
    let id: String
    let href: URL?
    let rel: String?
    let render: String?
    let width: Int
    let height: Int
    let size: Int

    init(from mediaLink: MediaLink) {
        self.id = mediaLink.href ?? UUID().uuidString
        self.href = mediaLink.href.flatMap { URL(string: $0) }
        self.rel = mediaLink.rel
        self.render = mediaLink.render
        self.width = Int(mediaLink.width)
        self.height = Int(mediaLink.height)
        self.size = Int(mediaLink.size)
    }

    init(id: String, href: URL?, rel: String?, render: String?, width: Int, height: Int, size: Int) {
        self.id = id
        self.href = href
        self.rel = rel
        self.render = render
        self.width = width
        self.height = height
        self.size = size
    }
}

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
    let links: [MediaLinkViewState]

    /// Creates view state from Core Data MediaItem entity
    init(from mediaItem: MediaItem) {
        self.id = mediaItem.nasaID ?? UUID().uuidString
        self.nasaID = mediaItem.nasaID ?? ""
        self.title = mediaItem.title ?? "Unknown"
        self.center = mediaItem.center
        self.description = mediaItem.itemDescription
        self.dateCreated = mediaItem.dateCreated

        // Convert links to view state
        if let mediaLinks = mediaItem.links as? Set<MediaLink> {
            self.links = mediaLinks.map { MediaLinkViewState(from: $0) }
                .sorted { ($0.rel ?? "") < ($1.rel ?? "") } // Sort by rel type
            self.assetCount = self.links.count

            // Find preview/thumbnail URL from links
            let previewLink = mediaLinks.first { $0.rel == "preview" } ?? mediaLinks.first
            self.thumbnailURL = previewLink?.href.flatMap { URL(string: $0) }
        } else {
            self.links = []
            self.assetCount = 0
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
        dateCreated: Date?,
        links: [MediaLinkViewState]
    ) {
        self.id = id
        self.nasaID = nasaID
        self.title = title
        self.center = center
        self.description = description
        self.assetCount = assetCount
        self.thumbnailURL = thumbnailURL
        self.dateCreated = dateCreated
        self.links = links
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
        dateCreated: Date? = Date(),
        links: [MediaLinkViewState] = [
            MediaLinkViewState(
                id: "1",
                href: URL(string: "https://images-assets.nasa.gov/image/PIA12345/PIA12345~thumb.jpg"),
                rel: "preview",
                render: "image",
                width: 100,
                height: 100,
                size: 15000
            ),
            MediaLinkViewState(
                id: "2",
                href: URL(string: "https://images-assets.nasa.gov/image/PIA12345/PIA12345~medium.jpg"),
                rel: "alternate",
                render: "image",
                width: 800,
                height: 600,
                size: 250000
            ),
            MediaLinkViewState(
                id: "3",
                href: URL(string: "https://images-assets.nasa.gov/image/PIA12345/PIA12345~large.jpg"),
                rel: "canonical",
                render: "image",
                width: 1920,
                height: 1080,
                size: 850000
            )
        ]
    ) -> MediaItemViewState {
        MediaItemViewState(
            id: id,
            nasaID: nasaID,
            title: title,
            center: center,
            description: description,
            assetCount: assetCount,
            thumbnailURL: thumbnailURL,
            dateCreated: dateCreated,
            links: links
        )
    }
}
