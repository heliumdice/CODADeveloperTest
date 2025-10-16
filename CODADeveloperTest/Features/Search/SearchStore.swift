//
//  SearchStore.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation
import Observation

/// Store managing search state and coordinating API + persistence operations
@MainActor
@Observable
final class SearchStore {
    // MARK: - State

    var query: String = "" {
        didSet {
            // Persist last search query
            UserDefaults.standard.set(query, forKey: "lastSearchQuery")
        }
    }
    var isLoading: Bool = false
    var error: String?
    var items: [MediaItemViewState] = []

    // MARK: - Dependencies

    private let apiService: NASAAPIServiceProtocol
    private let repository: MediaRepository

    // MARK: - Initialization

    init(apiService: NASAAPIServiceProtocol, repository: MediaRepository) {
        self.apiService = apiService
        self.repository = repository

        // Restore last search query
        if let lastQuery = UserDefaults.standard.string(forKey: "lastSearchQuery"),
           !lastQuery.isEmpty {
            self.query = lastQuery
        }
    }

    // MARK: - Actions

    /// Loads cached data for the current query from Core Data
    func loadCached() async {
        let mediaItems = await repository.fetchMediaForSearchTerm(query)
        self.items = mediaItems.map { MediaItemViewState(from: $0) }
    }

    /// Performs a search: fetches from API, persists to Core Data, then refreshes UI
    /// Falls back to cached data if offline
    func search() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "Please enter a search term"
            return
        }

        isLoading = true
        error = nil

        do {
            // 1. Fetch from NASA API
            let results = try await apiService.search(query: query)

            // 2. Persist to Core Data
            try await repository.saveSearchResults(results, for: query)

            // 3. Refresh UI from Core Data (single source of truth)
            await loadCached()

        } catch let networkError as NetworkError {
            // If network error, try to load cached data
            await loadCached()

            if items.isEmpty {
                // Only show error if we have no cached data
                self.error = networkError.localizedDescription
            } else {
                // We have cached data, clear error
                self.error = nil
            }
        } catch {
            // Try to load cached data for other errors too
            await loadCached()

            if items.isEmpty {
                self.error = "An unexpected error occurred: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

}
