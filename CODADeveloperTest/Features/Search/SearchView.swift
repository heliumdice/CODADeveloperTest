//
//  SearchView.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import SwiftUI

struct SearchView: View {

    @Environment(SearchStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("NASA Media Browser")
                .searchable(
                    text: Bindable(store).query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search NASA media..."
                )
                .onSubmit(of: .search) {
                    Task { await store.search() }
                }
                .task {
                    // Load cached data when view appears
                    if !store.query.isEmpty {
                        await store.loadCached() // Show cached immediately without loading spinner
                    }
                    // Load recent searches
                    await store.loadRecentSearches()
                }
                .onChange(of: store.query) { oldQuery, newQuery in
                    // Clear results when query is cleared
                    if newQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        store.items = []
                        store.error = nil
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Refresh when app becomes active (e.g., after turning off airplane mode)
                    if oldPhase == .background && newPhase == .active && !store.query.isEmpty {
                        Task {
                            await store.search()
                        }
                    }
                }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            LoadingView()
        } else if let error = store.error {
            ErrorView(message: error) {
                Task { await store.search() }
            }
        } else if store.items.isEmpty {
            // Show search history if query is empty and we have history
            if store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.recentSearches.isEmpty {
                SearchHistoryView(
                    recentSearches: store.recentSearches,
                    onSelectSearch: { searchTerm in
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismissSearch()
                        Task { await store.selectSearchFromHistory(searchTerm) }
                    }
                )
            } else {
                EmptyStateView()
            }
        } else {
            mediaList
        }
    }

    private var mediaList: some View {
        List(store.items) { item in
            NavigationLink(value: item) {
                MediaItemRow(item: item)
            }
        }
        .navigationDestination(for: MediaItemViewState.self) { item in
            DetailView(item: item)
        }
        .listStyle(.plain)
    }

}

// MARK: - Supporting Views

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching NASA media...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enter a search term and tap Search to find NASA media")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SearchHistoryView: View {
    let recentSearches: [String]
    let onSelectSearch: (String) -> Void

    var body: some View {
        List {
            Section {
                ForEach(recentSearches, id: \.self) { searchTerm in
                    Button(action: {
                        onSelectSearch(searchTerm)
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Text(searchTerm)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("Recent Searches")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Previews

#Preview("Search View") {
    SearchView()
        .environment(SearchStore(
            apiService: NASAAPIService(),
            repository: MediaRepository(coreDataManager: CoreDataManager(inMemory: true))
        ))
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Error") {
    ErrorView(message: "Failed to connect to NASA API") {
        print("Retry tapped")
    }
}

#Preview("Empty State") {
    EmptyStateView()
}

#Preview("Search History") {
    SearchHistoryView(
        recentSearches: ["mars", "apollo", "moon", "earth", "jupiter"],
        onSelectSearch: { searchTerm in
            print("Selected: \(searchTerm)")
        }
    )
}
