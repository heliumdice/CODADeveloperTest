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

    @Test
    func testSearchResultsClearStaleJoins() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchTerm = "mars"

        // First search: Save 5 items
        let firstSearchItems = [
            createSampleSearchItem(nasaId: "PIA001", title: "Item 1"),
            createSampleSearchItem(nasaId: "PIA002", title: "Item 2"),
            createSampleSearchItem(nasaId: "PIA003", title: "Item 3"),
            createSampleSearchItem(nasaId: "PIA004", title: "Item 4"),
            createSampleSearchItem(nasaId: "PIA005", title: "Item 5")
        ]
        try await repository.saveSearchResults(firstSearchItems, for: searchTerm)

        // Verify 5 items are cached
        let firstFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(firstFetch.count == 5)

        // Second search: NASA returns only 2 items (simulating API returning fewer results)
        let secondSearchItems = [
            createSampleSearchItem(nasaId: "PIA006", title: "New Item 1"),
            createSampleSearchItem(nasaId: "PIA007", title: "New Item 2")
        ]
        try await repository.saveSearchResults(secondSearchItems, for: searchTerm)

        // Verify only 2 items are now cached (old joins should be cleared)
        let secondFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(secondFetch.count == 2)
        #expect(secondFetch.contains { $0.nasaID == "PIA006" })
        #expect(secondFetch.contains { $0.nasaID == "PIA007" })

        // Verify old items are NOT returned (stale joins were cleared)
        #expect(!secondFetch.contains { $0.nasaID == "PIA001" })
        #expect(!secondFetch.contains { $0.nasaID == "PIA002" })
        #expect(!secondFetch.contains { $0.nasaID == "PIA003" })
    }

    @Test
    func testSearchResultsHandleZeroResults() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchTerm = "apollo"

        // First search: Save 3 items
        let firstSearchItems = [
            createSampleSearchItem(nasaId: "PIA100", title: "Apollo 1"),
            createSampleSearchItem(nasaId: "PIA101", title: "Apollo 2"),
            createSampleSearchItem(nasaId: "PIA102", title: "Apollo 3")
        ]
        try await repository.saveSearchResults(firstSearchItems, for: searchTerm)

        // Verify 3 items are cached
        let firstFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(firstFetch.count == 3)

        // Second search: NASA returns zero results (edge case)
        try await repository.saveSearchResults([], for: searchTerm)

        // Verify no items are returned (all joins cleared, none created)
        let secondFetch = await repository.fetchMediaForSearchTerm(searchTerm)
        #expect(secondFetch.isEmpty)
    }

    @Test
    func testRecentSearchesOrderByRecency() async throws {
        let coreDataManager = createInMemoryCoreDataManager()
        let repository = await MediaRepository(coreDataManager: coreDataManager)

        let searchItem = createSampleSearchItem()

        // Perform searches in this order: mars -> apollo -> jupiter
        try await repository.saveSearchResults([searchItem], for: "mars")
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay

        try await repository.saveSearchResults([searchItem], for: "apollo")
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay

        try await repository.saveSearchResults([searchItem], for: "jupiter")

        // Recent searches should be ordered: jupiter, apollo, mars
        let recentSearches = await repository.fetchRecentSearchQueries(limit: 10)
        #expect(recentSearches.count == 3)
        #expect(recentSearches[0].term == "jupiter")
        #expect(recentSearches[1].term == "apollo")
        #expect(recentSearches[2].term == "mars")

        // Now search "mars" again - it should bubble to the top
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        try await repository.saveSearchResults([searchItem], for: "mars")

        // Recent searches should now be: mars, jupiter, apollo
        let updatedSearches = await repository.fetchRecentSearchQueries(limit: 10)
        #expect(updatedSearches.count == 3)
        #expect(updatedSearches[0].term == "mars") // Bubbled to top!
        #expect(updatedSearches[1].term == "jupiter")
        #expect(updatedSearches[2].term == "apollo")
    }
}
