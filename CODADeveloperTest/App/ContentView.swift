//
//  ContentView.swift
//  CODADeveloperTest
//
//  Created by Dickie on 14/10/2025.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        SearchView()
    }

}

#Preview {
    ContentView()
        .environment(SearchStore(
            apiService: NASAAPIService(),
            repository: MediaRepository(coreDataManager: CoreDataManager(inMemory: true))
        ))
}
