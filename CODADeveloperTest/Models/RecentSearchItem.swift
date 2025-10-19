//
//  RecentSearchItem.swift
//  CODADeveloperTest
//
//  Created by Dickie on 19/10/2025.
//

import Foundation

/// View state for recent search history item
struct RecentSearchItem: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let lastSearchedAt: Date
}
