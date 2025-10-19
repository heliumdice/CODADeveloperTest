# NASA Media Browser

A native iOS application that integrates with the NASA Image and Video Library API to search, display, and persist space-related media content.

## Overview

NASA Media Browser is a SwiftUI-based iOS app that allows users to search NASA's extensive media library, view detailed information about space exploration imagery, and access content offline through Core Data persistence.

## Features

### Core Functionality
- **Search NASA Media**: Search the NASA Image and Video Library with configurable search terms
- **Media Display**: View search results with thumbnails, titles, center information, and descriptions
- **Asset Preview**: Navigate to detailed views showing all related media assets and links
- **Offline Support**: Automatic Core Data caching enables offline browsing of previously searched content
- **Search History**: Quick access to the last 10 search queries for convenient re-searching

### Technical Highlights
- **SwiftUI + Store Pattern**: Modern reactive architecture using `@Observable` for state management
- **Swift Concurrency**: Async/await throughout for modern asynchronous operations
- **Core Data Persistence**: Many-to-many relationships with proper upsert logic
- **Offline-First**: Cached data displayed immediately while background refresh occurs
- **Two-Tier Image Caching**: Memory (NSCache) + Disk (URLCache) for optimal performance and persistence
- **Comprehensive Testing**: Unit tests for DTOs, repositories, and store logic

## Architecture

### Store Pattern (Single Source of Truth)

The app follows a **unidirectional data flow** architecture, similar to Redux/Flux patterns but adapted for SwiftUI and iOS. This is an industry-standard approach used by production apps like Twitter, Instagram, and Slack.

**Key Principle**: Core Data is the **single source of truth**. The UI never reads directly from the API—data always flows through Core Data first.

#### Components
- **SearchStore**: Manages search state and coordinates between API service and repository. Marked `@Observable` for SwiftUI reactivity.
- **NASAAPIService**: Handles network requests to NASA API. Protocol-based for testability.
- **MediaRepository**: Manages all Core Data operations (fetch, save, relationships, upsert logic).
- **Views**: Pure presentation layer reading from Store via `@Environment`. No business logic.

### Data Flow

#### Happy Path (Online)
```
1. User taps search
   ↓
2. SearchView triggers SearchStore.search()
   ↓
3. SearchStore calls APIService.search()
   ↓
4. APIService fetches from NASA API
   ↓
5. SearchStore calls Repository.saveSearchResults()
   ↓
6. Repository persists to Core Data
   ↓
7. SearchStore calls Repository.fetch()
   ↓
8. Repository reads from Core Data
   ↓
9. SearchStore updates @Observable items property
   ↓
10. SearchView automatically re-renders (SwiftUI observation)
```

#### Offline Path (Network Unavailable)
```
1. User taps search
   ↓
2. SearchStore.search() attempts API call
   ↓
3. API throws NetworkError
   ↓
4. SearchStore catches error, calls Repository.fetch()
   ↓
5. Repository returns cached data from Core Data
   ↓
6. SearchStore updates items with cached data
   ↓
7. SearchView renders cached results (no error shown)
```

**Why This Pattern?**
- ✅ **Offline-first**: App works seamlessly without network
- ✅ **Consistent state**: One source of truth eliminates sync bugs
- ✅ **Testable**: Can test with in-memory Core Data
- ✅ **Predictable**: Unidirectional flow is easy to reason about
- ✅ **Scalable**: Used successfully in large production apps

**Code Example** (from SearchStore.swift):
```swift
func search() async {
    do {
        // 1. Fetch from NASA API
        let results = try await apiService.search(query: query)

        // 2. Persist to Core Data
        try await repository.saveSearchResults(results, for: query)

        // 3. Refresh UI from Core Data (single source of truth)
        await loadCached()

    } catch {
        // 4. On error, try loading cached data
        await loadCached()
        if items.isEmpty {
            self.error = error.localizedDescription
        }
    }
}
```

## Technologies

- **iOS 18.0+** (SwiftUI lifecycle)
- **Swift 5.0+** (modern concurrency with async/await)
- **SwiftUI** (declarative UI)
- **Core Data** (local persistence)
- **URLCache** (disk-based image caching)
- **Swift Testing** (unit tests)

## Project Structure

```
CODADeveloperTest/
├── App/
│   └── CODADeveloperTestApp.swift      # App entry point
├── Features/
│   ├── Search/
│   │   ├── SearchView.swift            # Main search interface
│   │   ├── SearchStore.swift           # Search state management
│   │   └── MediaItemRow.swift          # Search result row component
│   └── Detail/
│       └── DetailView.swift            # Asset detail screen
├── Data/
│   ├── API/
│   │   ├── NASAAPIService.swift        # Network layer
│   │   └── SearchResponseDTO.swift     # API response models
│   └── Persistence/
│       ├── CoreDataManager.swift       # Core Data stack
│       ├── MediaRepository.swift       # Data access layer
│       └── CODADeveloperTest.xcdatamodeld
├── Models/
│   └── MediaItemViewState.swift        # View state models
├── ViewModifiers/
│   └── SearchToolbarModifier.swift     # iOS 26+ bottom toolbar search placement
└── Utilities/
    ├── ImageLoader.swift               # Two-tier image caching (memory + disk)
    ├── CachedAsyncImage.swift          # SwiftUI image view with caching
    └── ImageLoaderEnvironment.swift    # Environment key for dependency injection

CODADeveloperTestTests/
├── NASAAPIDTOTests.swift               # DTO decoding tests
├── MediaRepositoryTests.swift          # Repository logic tests
└── SearchStoreTests.swift              # Store behaviour tests
```

## Core Data Model

### Entities
- **SearchQuery**: Stores unique search terms with timestamps
- **MediaItem**: NASA media metadata (NASA ID, title, description, etc.)
- **MediaLink**: Asset URLs and metadata (preview images, videos)
- **SearchQueryItem**: Join entity for many-to-many relationship

### Relationships
```
SearchQuery (1) ↔ (Many) SearchQueryItem (Many) ↔ (1) MediaItem (1) ↔ (Many) MediaLink
```

## Key Implementation Details

### Offline-First Strategy
1. User launches app → cached data loads immediately
2. Background network refresh starts automatically
3. New data persists to Core Data
4. UI updates from Core Data (single source of truth)
5. If network fails, cached data remains visible

### Search History
- Automatically tracks last 10 unique search queries
- Displays when search field is empty
- Tap to instantly re-run previous searches
- Persists across app launches via Core Data

### Image Caching
The app implements a **two-tier caching strategy** for optimal performance:

**Memory Cache (NSCache)**:
- 200MB capacity, stores up to 1,000 images
- Fastest access (checked first)
- Automatically evicts on memory pressure

**Disk Cache (URLCache)**:
- 200MB persistent storage
- Survives app restarts
- Checked if memory cache misses

**Cache Strategy**:
1. Check memory cache first ⚡ (instant)
2. Check disk cache second 💾 (fast)
3. Download from network 🌐 (slow, then cache for future)

This ensures smooth scrolling, offline image viewing, and minimal network usage.

## Known Issues

### iOS 26 DefaultToolbarItem Console Warning

When running on iOS 26+ simulators/devices, you may see the following console warning:

```
Ignoring searchBarPlacementBarButtonItem because its vending navigation item does not match
the view controller's.
```

**What it is:**
- A UIKit/SwiftUI bridging warning from the new iOS 26 `DefaultToolbarItem` API
- The code follows Apple's documented API correctly
- This appears to be an internal framework issue with how SwiftUI's `NavigationStack` bridges to UIKit

**Impact:**
- ✅ **No functional impact** - The search bar appears and works correctly in the bottom toolbar
- ⚠️ **Console noise only** - Safe to ignore
- 👀 **Expected behavior** - Search appears in bottom toolbar on iOS 26+, navigation bar on earlier versions

**Code location:** `ViewModifiers/SearchToolbarModifier.swift`

This type of warning is common with newly introduced iOS APIs and typically gets resolved in later iOS releases as Apple refines the internal implementation.

## API Integration

**Endpoint**: `https://images-api.nasa.gov/search`

**Query Parameters**: `?q={searchTerm}`

**Response Structure**:
```json
{
  "collection": {
    "items": [
      {
        "href": "https://...",
        "data": [{
          "nasa_id": "PIA12345",
          "title": "Mars Rover Discovery",
          "center": "JPL",
          "description": "...",
          "date_created": "2024-10-16T00:00:00Z",
          "media_type": "image"
        }],
        "links": [{
          "href": "https://.../thumb.jpg",
          "rel": "preview",
          "render": "image"
        }]
      }
    ]
  }
}
```

## Testing

### Test Coverage
- **DTO Tests**: JSON decoding with various edge cases (missing optionals, nil links)
- **Repository Tests**: Core Data operations, relationships, upsert logic
- **Store Tests**: Search flows, error handling, caching behaviour, empty states

All tests use in-memory Core Data and mock API services for isolation.

## Building

### Requirements
- Xcode 16.0+
- iOS 18.0+ SDK
- Swift 5.0+

## Future Enhancements

Potential improvements for production:
- Enhanced accessibility (VoiceOver optimisations)
- Localisation (i18n support)
- Video playback support
- Favorites/bookmarking functionality
- Advanced filtering (date range, media type, centre)
- Share media items
- iPad optimisation with split view
- Widget for recent searches
- App Clips for quick search

## License

This is a test project for demonstration purposes.

## Author

Created by Dickie for CODA iOS Developer Test

---
