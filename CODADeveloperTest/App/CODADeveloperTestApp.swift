//
//  CODADeveloperTestApp.swift
//  CODADeveloperTest
//
//  Created by Dickie on 14/10/2025.
//

import SwiftUI

@main
struct CODADeveloperTestApp: App {
    // Create dependencies (not singletons - injected via initializers)
    private let coreDataManager = CoreDataManager()
    @State private var searchStore: SearchStore

    init() {
        // Set up dependency graph
        let apiService = NASAAPIService()
        let repository = MediaRepository(coreDataManager: coreDataManager)
        let store = SearchStore(apiService: apiService, repository: repository)

        _searchStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchStore)
        }
    }
}
