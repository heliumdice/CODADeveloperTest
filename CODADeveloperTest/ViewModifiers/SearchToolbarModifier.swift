//
//  SearchToolbarModifier.swift
//  CODADeveloperTest
//
//  Created by Dickie on 19/10/2025.
//

import SwiftUI

/// Adds a bottom toolbar with DefaultToolbarItem on iOS 26+
///
/// This modifier places the search field in the bottom toolbar on iOS 26+ devices
/// using the new `DefaultToolbarItem` API. On earlier iOS versions, the search
/// field remains in its default navigation bar position.
///
/// Usage:
/// ```swift
/// .searchable(text: $searchText)
/// .modifier(SearchToolbarModifier())
/// ```
///
/// - Note: This may produce a console warning on iOS 26 about `searchBarPlacementBarButtonItem`
///   due to internal UIKit/SwiftUI bridging. This is a known framework issue and does not
///   affect functionality. See README.md "Known Issues" for details.
struct SearchToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
        } else {
            content
        }
    }
}
