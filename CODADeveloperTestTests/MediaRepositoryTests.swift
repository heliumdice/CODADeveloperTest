//
//  MediaRepositoryTests.swift
//  CODADeveloperTestTests
//
//  Created by Dickie on 16/10/2025.
//

import Foundation
import Testing
import CoreData
@testable import CODADeveloperTest

@Suite(.serialized)
struct MediaRepositoryTests: Sendable {

    // MARK: - Helper Methods

    /// Creates an in-memory Core Data stack for testing
    private func createInMemoryCoreDataManager() -> CoreDataManager {
        return CoreDataManager(inMemory: true)
    }

    /// Creates sample SearchItem for testing
    private func createSampleSearchItem(nasaId: String = "PIA12345", title: String = "Test Item") -> SearchItem {
        return SearchItem(
            href: "https://test.nasa.gov/collection.json",
            data: [
                SearchData(
                    nasaId: nasaId,
                    title: title,
                    center: "JPL",
                    description: "Test description",
                    dateCreated: Date(),
                    mediaType: "image",
                    location: "Mars",
                    photographer: "NASA",
                    keywords: ["test", "mars"]
                )
            ],
            links: [
                SearchLink(
                    href: "https://test.nasa.gov/thumb.jpg",
                    rel: "preview",
                    render: "image",
                    width: 100,
                    height: 100,
                    size: 5000
                )
            ]
        )
    }

    // MARK: - Tests

    @Test
    func testSaveAndFetchSearchResults() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchTerm = "mars"
        let searchItems = [
            createSampleSearchItem(nasaId: "PIA001", title: "Mars Image 1"),
            createSampleSearchItem(nasaId: "PIA002", title: "Mars Image 2")
        ]

        // Save search results
        try await repository.saveSearchResults(searchItems, for: searchTerm)

        // Fetch results
        let fetchedItems = await repository.fetchMediaForSearchTerm(searchTerm)

        // Verify results
        #expect(fetchedItems.count == 2)
        #expect(fetchedItems.contains { $0.nasaID == "PIA001" })
        #expect(fetchedItems.contains { $0.nasaID == "PIA002" })
    }

    @Test
    func testUpsertMediaItem() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchTerm = "test"
        let searchItem = createSampleSearchItem(nasaId: "PIA123", title: "Original Title")

        // First save
        try await repository.saveSearchResults([searchItem], for: searchTerm)
        let firstFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(firstFetch.count == 1)
        #expect(firstFetch[0].title == "Original Title")

        // Update same item with new title
        let updatedItem = createSampleSearchItem(nasaId: "PIA123", title: "Updated Title")
        try await repository.saveSearchResults([updatedItem], for: searchTerm)

        // Verify update (should still be 1 item, not 2)
        let secondFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(secondFetch.count == 1)
        #expect(secondFetch[0].title == "Updated Title")
    }

    @Test
    func testManyToManyRelationship() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchItem = createSampleSearchItem(nasaId: "PIA999", title: "Shared Item")

        // Save same item under two different search terms
        try await repository.saveSearchResults([searchItem], for: "mars")
        try await repository.saveSearchResults([searchItem], for: "rover")

        // Fetch results for both terms
        let marsResults = await repository.fetchMediaForSearchTerm("mars")
        let roverResults = await repository.fetchMediaForSearchTerm("rover")

        // Verify same item appears in both searches (many-to-many)
        #expect(marsResults.count == 1)
        #expect(roverResults.count == 1)
        #expect(marsResults[0].nasaID == "PIA999")
        #expect(roverResults[0].nasaID == "PIA999")
    }

    @Test
    func testSearchQueryUniqueness() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchItem = createSampleSearchItem()

        // Save same search term multiple times
        try await repository.saveSearchResults([searchItem], for: "mars")
        try await repository.saveSearchResults([searchItem], for: "mars")
        try await repository.saveSearchResults([searchItem], for: "mars")

        // Verify only one SearchQuery entity exists
        let context = await coreDataManager.viewContext
        let request = SearchQuery.fetchRequest()
        request.predicate = NSPredicate(format: "term == %@", "mars")

        let results = try context.fetch(request)
        #expect(results.count == 1)
    }

    @Test
    func testMediaLinksRelationship() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchItem = createSampleSearchItem(nasaId: "PIA777", title: "Item with Links")

        // Save item with links
        try await repository.saveSearchResults([searchItem], for: "test")

        // Fetch and verify links
        let fetchedItems = await repository.fetchMediaForSearchTerm("test")
        #expect(fetchedItems.count == 1)

        let mediaItem = fetchedItems[0]
        let links = mediaItem.links as? Set<MediaLink>
        #expect(links?.count == 1)

        let link = links?.first
        #expect(link?.href == "https://test.nasa.gov/thumb.jpg")
        #expect(link?.rel == "preview")
        #expect(link?.width == 100)
        #expect(link?.height == 100)
    }

    @Test
    func testHandleItemsWithNilLinks() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let itemWithoutLinks = SearchItem(
            href: nil,
            data: [
                SearchData(
                    nasaId: "PIA888",
                    title: "No Links Item",
                    center: "JPL",
                    description: nil,
                    dateCreated: nil,
                    mediaType: nil,
                    location: nil,
                    photographer: nil,
                    keywords: nil
                )
            ],
            links: nil
        )

        // Should not throw even with nil links
        try await repository.saveSearchResults([itemWithoutLinks], for: "test")

        let fetchedItems = await repository.fetchMediaForSearchTerm("test")
        #expect(fetchedItems.count == 1)
        #expect(fetchedItems[0].nasaID == "PIA888")

        let links = fetchedItems[0].links as? Set<MediaLink>
        #expect(links?.isEmpty == true || links == nil)
    }

    @Test
    func testEmptySearchResults() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        // Save empty array
        try await repository.saveSearchResults([], for: "empty")

        // Fetch should return empty array, not throw error
        let fetchedItems = await repository.fetchMediaForSearchTerm("empty")
        #expect(fetchedItems.isEmpty)
    }

    @Test
    func testFetchNonexistentSearchTerm() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        // Fetch a term that was never saved
        let fetchedItems = await repository.fetchMediaForSearchTerm("nonexistent")
        #expect(fetchedItems.isEmpty)
    }
}
