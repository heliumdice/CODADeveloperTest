//
//  ImageLoader.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation
import UIKit
import OSLog

extension Logger {
    static let imageLoader = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "imageLoader")
}

/// Service for loading and caching images asynchronously
/// Simplified version without actors - NSCache is already thread-safe
final class ImageLoader {

    // MARK: - Private Properties

    private let cache = NSCache<NSString, NSData>()
    private let session: URLSession

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session

        // Configure cache limits
        cache.countLimit = 100 // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        Logger.imageLoader.info("🖼️ ImageLoader initialized")
    }

    // MARK: - Public Methods

    /// Loads an image from a URL with caching
    /// - Parameter urlString: The URL string of the image
    /// - Returns: Data of the loaded image
    func loadImage(from urlString: String) async throws -> Data {
        Logger.imageLoader.info("🔍 Requesting image: \(urlString)")

        // Check cache first (NSCache is thread-safe)
        if let cachedData = cache.object(forKey: urlString as NSString) {
            Logger.imageLoader.info("💾 Found cached image (\(cachedData.length) bytes)")
            return cachedData as Data
        }

        // Download from network
        guard let url = URL(string: urlString) else {
            Logger.imageLoader.error("❌ Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }

        Logger.imageLoader.info("🌐 Downloading image from network...")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.imageLoader.error("❌ Invalid response type")
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            Logger.imageLoader.error("❌ HTTP error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        // Cache the data (NSCache is thread-safe)
        cache.setObject(data as NSData, forKey: urlString as NSString)
        Logger.imageLoader.info("✅ Downloaded and cached image (\(data.count) bytes)")

        return data
    }

    /// Clears the image cache
    func clearCache() {
        cache.removeAllObjects()
        Logger.imageLoader.info("🗑️ Image cache cleared")
    }
}
