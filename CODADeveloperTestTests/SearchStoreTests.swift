//
//  SearchStoreTests.swift
//  CODADeveloperTestTests
//
//  Created by Dickie on 16/10/2025.
//

import Foundation
import Testing
@testable import CODADeveloperTest

@Suite(.serialized)
@MainActor
struct SearchStoreTests: Sendable {

    // MARK: - Mock API Service

    final class MockAPIService: NASAAPIServiceProtocol {
        var shouldFail = false
        var mockResults: [SearchItem] = []

        func search(query: String) async throws -> [SearchItem] {
            if shouldFail {
                throw NetworkError.networkUnavailable
            }
            return mockResults
        }
    }

    // MARK: - Helper Methods

    private func createMockSearchItem(nasaId: String = "PIA123", title: String = "Test") -> SearchItem {
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
                    location: nil,
                    photographer: nil,
                    keywords: nil
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

    private func createTestStore() -> (SearchStore, MockAPIService, MediaRepository) {
        let mockAPI = MockAPIService()
        let coreDataManager = CoreDataManager(inMemory: true)
        let repository = MediaRepository(coreDataManager: coreDataManager)
        let store = SearchStore(apiService: mockAPI, repository: repository)
        return (store, mockAPI, repository)
    }

    // MARK: - Tests

    @Test
    func testInitialState() async throws {
        let (store, _, _) = createTestStore()

        #expect(store.query == "")
        #expect(store.isLoading == false)
        #expect(store.error == nil)
        #expect(store.items.isEmpty)
    }

    @Test
    func testSuccessfulSearch() async throws {
        let (store, mockAPI, _) = createTestStore()

        // Setup mock data
        mockAPI.mockResults = [
            createMockSearchItem(nasaId: "PIA001", title: "Result 1"),
            createMockSearchItem(nasaId: "PIA002", title: "Result 2")
        ]

        store.query = "mars"

        // Perform search
        await store.search()

        // Verify state
        #expect(store.isLoading == false)
        #expect(store.error == nil)
        #expect(store.items.count == 2)
        #expect(store.items.contains { $0.nasaID == "PIA001" })
        #expect(store.items.contains { $0.nasaID == "PIA002" })
    }

    @Test
    func testSearchWithEmptyQuery() async throws {
        let (store, _, _) = createTestStore()

        store.query = ""

        await store.search()

        // Should set error for empty query
        #expect(store.error == "Please enter a search term")
        #expect(store.items.isEmpty)
    }

    @Test
    func testSearchWithWhitespaceQuery() async throws {
        let (store, _, _) = createTestStore()

        store.query = "   "

        await store.search()

        // Should set error for whitespace-only query
        #expect(store.error == "Please enter a search term")
        #expect(store.items.isEmpty)
    }

    @Test
    func testSearchNetworkError() async throws {
        let (store, mockAPI, _) = createTestStore()

        // Setup mock to fail
        mockAPI.shouldFail = true
        store.query = "mars"

        await store.search()

        // Should handle error gracefully
        #expect(store.isLoading == false)
        #expect(store.error != nil)
        #expect(store.items.isEmpty)
    }

    @Test
    func testSearchNetworkErrorWithCachedData() async throws {
        let (store, mockAPI, _) = createTestStore()

        // First successful search
        mockAPI.mockResults = [createMockSearchItem(nasaId: "PIA123", title: "Cached Item")]
        store.query = "mars"
        await store.search()

        #expect(store.items.count == 1)
        #expect(store.error == nil)

        // Now make network fail
        mockAPI.shouldFail = true

        // Search again (should use cached data)
        await store.search()

        // Should show cached data, not error
        #expect(store.items.count == 1)
        #expect(store.items[0].nasaID == "PIA123")
        #expect(store.error == nil) // No error because we have cached data
    }

    @Test
    func testLoadCached() async throws {
        let (store, _, repository) = createTestStore()

        // Save some data first
        let searchItems = [createMockSearchItem(nasaId: "PIA999", title: "Cached")]
        try await repository.saveSearchResults(searchItems, for: "mars")

        store.query = "mars"

        // Load cached data
        await store.loadCached()

        // Verify cached data loaded
        #expect(store.items.count == 1)
        #expect(store.items[0].nasaID == "PIA999")
        #expect(store.items[0].title == "Cached")
    }

    @Test
    func testLoadCachedWithNoData() async throws {
        let (store, _, _) = createTestStore()

        store.query = "nonexistent"

        await store.loadCached()

        // Should return empty array, not error
        #expect(store.items.isEmpty)
    }

    @Test
    func testSearchPersistsData() async throws {
        let (store, mockAPI, repository) = createTestStore()

        mockAPI.mockResults = [createMockSearchItem(nasaId: "PIA555", title: "Persisted")]
        store.query = "test"

        await store.search()

        // Verify data was persisted to Core Data
        let fetchedItems = await repository.fetchMediaForSearchTerm("test")
        #expect(fetchedItems.count == 1)
        #expect(fetchedItems[0].nasaID == "PIA555")
    }

    @Test
    func testMultipleSearches() async throws {
        let (store, mockAPI, _) = createTestStore()

        // First search
        mockAPI.mockResults = [createMockSearchItem(nasaId: "PIA111", title: "First")]
        store.query = "mars"
        await store.search()

        #expect(store.items.count == 1)
        #expect(store.items[0].nasaID == "PIA111")

        // Second search (different query)
        mockAPI.mockResults = [createMockSearchItem(nasaId: "PIA222", title: "Second")]
        store.query = "moon"
        await store.search()

        #expect(store.items.count == 1)
        #expect(store.items[0].nasaID == "PIA222")
    }

    @Test
    func testLoadingState() async throws {
        let (store, mockAPI, _) = createTestStore()

        mockAPI.mockResults = [createMockSearchItem()]
        store.query = "test"

        // Check loading state transitions
        #expect(store.isLoading == false)

        let searchTask = Task {
            await store.search()
        }

        // Note: In real async tests, checking intermediate state is tricky
        // This verifies final state after completion
        await searchTask.value

        #expect(store.isLoading == false)
    }

    @Test
    func testErrorClearing() async throws {
        let (store, mockAPI, _) = createTestStore()

        // First: cause an error
        mockAPI.shouldFail = true
        store.query = "test"
        await store.search()

        #expect(store.error != nil)

        // Second: successful search should clear error
        mockAPI.shouldFail = false
        mockAPI.mockResults = [createMockSearchItem()]
        await store.search()

        #expect(store.error == nil)
        #expect(store.items.count == 1)
    }
}
