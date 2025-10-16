//
//  NASAAPIService.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .noData:
            return "No data received from server"
        case .decodingFailed(let error):
            return "Unable to process server response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class NASAAPIService {
    private let baseURL = "https://images-api.nasa.gov/search"
    private let session: URLSession

    init(session: URLSession = .shared) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        self.session = session
    }

    /// Searches the NASA Image and Video Library API
    /// - Parameter query: Search term (e.g., "mars", "apollo")
    /// - Returns: Array of SearchItem results from the API
    /// - Throws: NetworkError if the request fails
    func search(query: String) async throws -> [SearchItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NetworkError.invalidURL
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }

            guard httpResponse.statusCode == 200 else {
                throw NetworkError.networkError(
                    NSError(domain: "HTTP", code: httpResponse.statusCode)
                )
            }

            let decoder = JSONDecoder()
            // Convert API's snake_case keys (nasa_id, date_created) to Swift camelCase
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // Parse ISO8601 date strings (e.g., "2024-10-16T00:00:00Z") to Date objects
            decoder.dateDecodingStrategy = .iso8601

            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            return searchResponse.collection.items

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
