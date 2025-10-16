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
                    // Load cached data when view appears, then refresh from network
                    if !store.query.isEmpty {
                        await store.loadCached() // Show cached immediately
                        await store.search()      // Then refresh from network
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
            EmptyStateView()
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
