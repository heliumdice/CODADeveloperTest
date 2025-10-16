//
//  MediaRepository.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import CoreData
import Foundation

/// Handles all Core Data CRUD operations for media items
/// Implements upsert logic and many-to-many relationship management
final class MediaRepository {

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - Save Operations

    /// Saves search results to Core Data with proper relationship management
    /// - Parameters:
    ///   - items: Search results from NASA API
    ///   - term: Search term used for the query
    func saveSearchResults(_ items: [SearchItem], for term: String) async throws {
        let context = coreDataManager.newBackgroundContext()

        try await context.perform {
            // 1. Get or create SearchQuery
            let searchQuery = try self.getOrCreateSearchQuery(term, in: context)

            // 2. Process each search item
            for item in items {
                guard let firstData = item.data.first else { continue }

                // 3. Upsert MediaItem by nasaID
                let mediaItem = try self.getOrCreateMediaItem(from: firstData, in: context)

                // 4. Clear and recreate MediaLink children
                if let existingLinks = mediaItem.links as? Set<MediaLink> {
                    for link in existingLinks {
                        context.delete(link)
                    }
                }

                // Create new links from API response
                if let links = item.links {
                    for linkData in links {
                        let mediaLink = MediaLink(context: context)
                        mediaLink.href = linkData.href
                        mediaLink.rel = linkData.rel
                        mediaLink.render = linkData.render
                        mediaLink.width = Int64(linkData.width ?? 0)
                        mediaLink.height = Int64(linkData.height ?? 0)
                        mediaLink.size = Int64(linkData.size ?? 0)
                        mediaLink.mediaItem = mediaItem
                    }
                }

                // 5. Create or verify SearchQueryItem join relationship
                let relationshipExists = (searchQuery.searchQueryItems as? Set<SearchQueryItem>)?.contains { queryItem in
                    queryItem.mediaItem?.nasaID == mediaItem.nasaID
                } ?? false

                if !relationshipExists {
                    let searchQueryItem = SearchQueryItem(context: context)
                    searchQueryItem.createdAt = Date()
                    searchQueryItem.searchQuery = searchQuery
                    searchQueryItem.mediaItem = mediaItem
                }
            }

            // 6. Save context
            try context.save()
        }

        // Refresh view context to ensure UI updates
        await MainActor.run {
            self.coreDataManager.viewContext.refreshAllObjects()
        }
    }

    // MARK: - Fetch Operations

    /// Fetches media items for a specific search term
    /// - Parameter term: Search term to filter by
    /// - Returns: Array of MediaItem entities
    func fetchMediaForSearchTerm(_ term: String) async -> [MediaItem] {
        let context = coreDataManager.viewContext

        return await context.perform {
            let request: NSFetchRequest<MediaItem> = MediaItem.fetchRequest()
            // Traverse many-to-many relationship: MediaItem -> SearchQueryItem -> SearchQuery
            request.predicate = NSPredicate(
                format: "ANY searchQueries.searchQuery.term == %@",
                term
            )
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \MediaItem.title, ascending: true)
            ]

            do {
                return try context.fetch(request)
            } catch {
                assertionFailure("Failed to fetch media items: \(error.localizedDescription)")
                return []
            }
        }
    }

    /// Fetches recent search queries sorted by most recent
    /// - Parameter limit: Maximum number of queries to return (default: 10)
    /// - Returns: Array of search query strings
    func fetchRecentSearchQueries(limit: Int = 10) async -> [String] {
        let context = coreDataManager.viewContext

        return await context.perform {
            let request: NSFetchRequest<SearchQuery> = SearchQuery.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \SearchQuery.createdAt, ascending: false)
            ]
            request.fetchLimit = limit

            do {
                let queries = try context.fetch(request)
                return queries.compactMap { $0.term }
            } catch {
                assertionFailure("Failed to fetch recent queries: \(error.localizedDescription)")
                return []
            }
        }
    }

    // MARK: - Private Helpers

    /// Gets existing SearchQuery or creates a new one (ensures uniqueness by term)
    private func getOrCreateSearchQuery(_ term: String, in context: NSManagedObjectContext) throws -> SearchQuery {
        let fetchRequest: NSFetchRequest<SearchQuery> = SearchQuery.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "term == %@", term)
        fetchRequest.fetchLimit = 1

        if let existing = try context.fetch(fetchRequest).first {
            return existing
        }

        let newQuery = SearchQuery(context: context)
        newQuery.term = term
        newQuery.createdAt = Date()
        return newQuery
    }

    /// Gets existing MediaItem or creates a new one (upsert by nasaID)
    private func getOrCreateMediaItem(from data: SearchData, in context: NSManagedObjectContext) throws -> MediaItem {
        let fetchRequest: NSFetchRequest<MediaItem> = MediaItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "nasaID == %@", data.nasaId)
        fetchRequest.fetchLimit = 1

        let mediaItem: MediaItem
        if let existing = try context.fetch(fetchRequest).first {
            mediaItem = existing
        } else {
            mediaItem = MediaItem(context: context)
            mediaItem.nasaID = data.nasaId
        }

        // Update properties (whether new or existing)
        mediaItem.title = data.title
        mediaItem.center = data.center
        mediaItem.itemDescription = data.description
        mediaItem.dateCreated = data.dateCreated
        mediaItem.mediaType = data.mediaType
        mediaItem.location = data.location
        mediaItem.photographer = data.photographer
        mediaItem.keywords = data.keywords as NSObject?

        return mediaItem
    }
}
