//
//  NASAAPIDTOTests.swift
//  CODADeveloperTestTests
//
//  Created by Dickie on 14/10/2025.
//

import Foundation
import Testing
@testable import CODADeveloperTest

@Suite
struct NASAAPIDTOTests: Sendable {

    // MARK: - Tests

    @Test
    @MainActor
    func testDecodeCompleteResponse() throws {
        // Sample JSON response from NASA API with all fields populated
        let validJSONWithLinks = """
        {
            "collection": {
                "items": [
                    {
                        "href": "https://images-assets.nasa.gov/image/PIA12345/collection.json",
                        "data": [
                            {
                                "nasa_id": "PIA12345",
                                "title": "Mars Rover Discovery",
                                "center": "JPL",
                                "description": "A stunning view of the Martian surface",
                                "date_created": "2024-10-16T00:00:00Z",
                                "media_type": "image",
                                "location": "Mars",
                                "photographer": "NASA",
                                "keywords": ["mars", "rover", "discovery"]
                            }
                        ],
                        "links": [
                            {
                                "href": "https://images-assets.nasa.gov/image/PIA12345/PIA12345~thumb.jpg",
                                "rel": "preview",
                                "render": "image",
                                "width": 100,
                                "height": 100,
                                "size": 5000
                            }
                        ]
                    }
                ]
            }
        }
        """

        let decoder = JSONDecoder()
        // Configure decoder to match API service setup
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let data = validJSONWithLinks.data(using: .utf8)!
        let response = try decoder.decode(SearchResponse.self, from: data)

        // Verify collection structure
        #expect(response.collection.items.count == 1)

        // Verify first item
        let item = response.collection.items[0]
        #expect(item.href == "https://images-assets.nasa.gov/image/PIA12345/collection.json")
        #expect(item.data.count == 1)
        #expect(item.links?.count == 1)

        // Verify data fields (snake_case converted to camelCase)
        let itemData = item.data[0]
        #expect(itemData.nasaId == "PIA12345")
        #expect(itemData.title == "Mars Rover Discovery")
        #expect(itemData.center == "JPL")
        #expect(itemData.description == "A stunning view of the Martian surface")
        #expect(itemData.mediaType == "image")
        #expect(itemData.location == "Mars")
        #expect(itemData.photographer == "NASA")
        #expect(itemData.keywords?.count == 3)
        #expect(itemData.dateCreated != nil)

        // Verify links
        let link = item.links![0]
        #expect(link.href == "https://images-assets.nasa.gov/image/PIA12345/PIA12345~thumb.jpg")
        #expect(link.rel == "preview")
        #expect(link.render == "image")
        #expect(link.width == 100)
        #expect(link.height == 100)
        #expect(link.size == 5000)
    }

    @Test
    @MainActor
    func testDecodeMissingOptionalFields() throws {
        // Sample JSON with missing optional fields to test graceful handling
        let validJSONWithoutOptionals = """
        {
            "collection": {
                "items": [
                    {
                        "data": [
                            {
                                "nasa_id": "PIA99999",
                                "title": "Test Item"
                            }
                        ]
                    }
                ]
            }
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let data = validJSONWithoutOptionals.data(using: .utf8)!
        let response = try decoder.decode(SearchResponse.self, from: data)

        let item = response.collection.items[0]
        let itemData = item.data[0]

        // Verify required fields exist
        #expect(itemData.nasaId == "PIA99999")
        #expect(itemData.title == "Test Item")

        // Verify optional fields are nil
        #expect(item.href == nil)
        #expect(item.links == nil)
        #expect(itemData.center == nil)
        #expect(itemData.description == nil)
        #expect(itemData.dateCreated == nil)
        #expect(itemData.mediaType == nil)
        #expect(itemData.location == nil)
        #expect(itemData.photographer == nil)
        #expect(itemData.keywords == nil)
    }

    @Test
    @MainActor
    func testDecodeNilLinks() throws {
        // Sample JSON with nil links array to test edge case
        let validJSONWithNilLinks = """
        {
            "collection": {
                "items": [
                    {
                        "href": "https://test.nasa.gov/collection.json",
                        "data": [
                            {
                                "nasa_id": "TEST123",
                                "title": "Test Without Links",
                                "center": "TEST"
                            }
                        ],
                        "links": null
                    }
                ]
            }
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let data = validJSONWithNilLinks.data(using: .utf8)!
        let response = try decoder.decode(SearchResponse.self, from: data)

        let item = response.collection.items[0]

        // Verify item decodes successfully even with nil links
        #expect(item.data[0].nasaId == "TEST123")
        #expect(item.data[0].title == "Test Without Links")
        #expect(item.links == nil)
    }

    @Test
    @MainActor
    func testInvalidJSON() throws {
        let invalidJSON = "{ invalid json }"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let data = invalidJSON.data(using: .utf8)!

        // Expect decoding to throw an error
        #expect(throws: Error.self) {
            try decoder.decode(SearchResponse.self, from: data)
        }
    }
}
