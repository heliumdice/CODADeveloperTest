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

    var query: String = "mars"
    var isLoading: Bool = false
    var error: String?
    var items: [MediaItemViewState] = []

    // MARK: - Dependencies

    private let apiService: NASAAPIService
    private let repository: MediaRepository

    // MARK: - Initialization

    init(apiService: NASAAPIService, repository: MediaRepository) {
        self.apiService = apiService
        self.repository = repository
    }

    // MARK: - Actions

    /// Loads cached data for the current query from Core Data
    func loadCached() async {
        let mediaItems = await repository.fetchMediaForSearchTerm(query)
        self.items = mediaItems.map { MediaItemViewState(from: $0) }
    }

    /// Performs a search: fetches from API, persists to Core Data, then refreshes UI
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
            self.error = networkError.localizedDescription
        } catch {
            self.error = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
