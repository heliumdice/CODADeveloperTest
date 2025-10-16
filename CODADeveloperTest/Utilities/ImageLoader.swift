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
/// Uses both in-memory NSCache and disk-based URLCache for persistence
final class ImageLoader {

    // MARK: - Constants

    private static let memoryCacheLimit = 1000 // Max number of images in memory
    private static let memoryCacheSizeLimit = 200 * 1024 * 1024 // 200MB
    private static let diskCacheSizeLimit = 200 * 1024 * 1024 // 200MB
    private static let diskCachePath = "image_cache"

    // MARK: - Private Properties

    private let memoryCache = NSCache<NSString, NSData>()
    private let session: URLSession

    // MARK: - Initialization

    init(session: URLSession? = nil) {
        if let session = session {
            Logger.imageLoader.info("🖼️ ImageLoader: Using provided URLSession")
            self.session = session
        } else {
            Logger.imageLoader.info("🖼️ ImageLoader: Creating new URLSession with disk cache")

            // Configure URLSession with disk cache for persistence
            let configuration = URLSessionConfiguration.default

            // Set up URLCache with disk storage
            let urlCache = URLCache(
                memoryCapacity: Self.memoryCacheSizeLimit,
                diskCapacity: Self.diskCacheSizeLimit,
                diskPath: Self.diskCachePath
            )

            Logger.imageLoader.info("📦 URLCache created - Memory: \(urlCache.memoryCapacity / 1024 / 1024)MB, Disk: \(urlCache.diskCapacity / 1024 / 1024)MB")
            Logger.imageLoader.info("📊 Current cache usage - Memory: \(urlCache.currentMemoryUsage / 1024)KB, Disk: \(urlCache.currentDiskUsage / 1024)KB")

            configuration.urlCache = urlCache
            configuration.requestCachePolicy = .returnCacheDataElseLoad

            Logger.imageLoader.info("⚙️ Cache policy: \(configuration.requestCachePolicy.rawValue)")

            self.session = URLSession(configuration: configuration)
        }

        // Configure in-memory cache for faster access
        memoryCache.countLimit = Self.memoryCacheLimit
        memoryCache.totalCostLimit = Self.memoryCacheSizeLimit

        Logger.imageLoader.info("✅ ImageLoader initialized - Memory cache limit: \(Self.memoryCacheLimit) images / \(Self.memoryCacheSizeLimit / 1024 / 1024)MB")
    }

    // MARK: - Public Methods

    /// Loads an image from a URL with caching
    /// - Parameter urlString: The URL string of the image
    /// - Returns: Data of the loaded image
    func loadImage(from urlString: String) async throws -> Data {
        let shortURL = (urlString.components(separatedBy: "/").last ?? urlString).prefix(50)
        Logger.imageLoader.info("🔍 Requesting: \(shortURL)")

        // Check memory cache first (fastest)
        if let cachedData = memoryCache.object(forKey: urlString as NSString) {
            Logger.imageLoader.info("⚡ Memory cache HIT (\(cachedData.length / 1024)KB)")
            return cachedData as Data
        }

        // Create URL and request
        guard let url = URL(string: urlString) else {
            Logger.imageLoader.error("❌ Invalid URL")
            throw URLError(.badURL)
        }

        // Check if image is in disk cache first
        let request = URLRequest(url: url)
        Logger.imageLoader.info("🔎 Checking disk cache...")

        if let urlCache = session.configuration.urlCache {
            if let cachedResponse = urlCache.cachedResponse(for: request) {
                Logger.imageLoader.info("💾 Disk cache HIT (\(cachedResponse.data.count / 1024)KB) - Usage: \(urlCache.currentDiskUsage / 1024)KB / \(urlCache.diskCapacity / 1024 / 1024)MB")
                // Store in memory cache for faster access next time
                memoryCache.setObject(cachedResponse.data as NSData, forKey: urlString as NSString)
                return cachedResponse.data
            }
        } else {
            Logger.imageLoader.warning("⚠️ No URLCache configured!")
        }

        // Download from network
        Logger.imageLoader.info("🌐 Downloading from network...")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.imageLoader.error("❌ Invalid response type")
            throw URLError(.badServerResponse)
        }

        Logger.imageLoader.info("📥 HTTP \(httpResponse.statusCode) - Size: \(data.count / 1024)KB")

        guard httpResponse.statusCode == 200 else {
            Logger.imageLoader.error("❌ HTTP error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        // Store in memory cache for faster access next time
        memoryCache.setObject(data as NSData, forKey: urlString as NSString)
        Logger.imageLoader.info("✅ Downloaded and stored in memory cache")

        // Check if URLSession automatically cached it to disk
        if let urlCache = session.configuration.urlCache {
            Logger.imageLoader.info("📊 After download - Disk usage: \(urlCache.currentDiskUsage / 1024)KB")
        }

        return data
    }

    /// Clears the image cache (both memory and disk)
    func clearCache() {
        memoryCache.removeAllObjects()
        session.configuration.urlCache?.removeAllCachedResponses()
        Logger.imageLoader.info("🗑️ Image cache cleared (memory and disk)")
    }
}
