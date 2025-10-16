//
//  CODADeveloperTestApp.swift
//  CODADeveloperTest
//
//  Created by Dickie on 14/10/2025.
//

import SwiftUI

@main
struct CODADeveloperTestApp: App {

    @State private var searchStore: SearchStore
    @State private var networkMonitor = NetworkMonitor()

    private let coreDataManager = CoreDataManager()
    private let imageLoader = ImageLoader()

    init() {
        let apiService = NASAAPIService()
        let repository = MediaRepository(coreDataManager: coreDataManager)
        let store = SearchStore(apiService: apiService, repository: repository)

        _searchStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchStore)
                .environment(networkMonitor)
                .environment(\.imageLoader, imageLoader)
        }
    }
}
