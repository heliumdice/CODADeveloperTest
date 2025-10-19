//
//  TimeInterval+Constants.swift
//  CODADeveloperTest
//
//  Created by Dickie on 19/10/2025.
//

import Foundation

extension TimeInterval {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 60 * minute
    static let day: TimeInterval = 24 * hour
    static let week: TimeInterval = 7 * day
    static let month: TimeInterval = 30 * day
}

extension Date {
    /// Returns a compact relative time string showing only the largest unit
    /// Examples: "2m", "3h", "5d", "2w", "1mo"
    func relativeTimeCompact() -> String {
        return self.formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
    }
}
