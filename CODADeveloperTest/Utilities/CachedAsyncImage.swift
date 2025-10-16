//
//  CachedAsyncImage.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import SwiftUI
import OSLog

/// AsyncImage wrapper that uses ImageLoader for caching
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {

    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @Environment(\.imageLoader) private var imageLoader
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if didFail {
                failure()
                    .onTapGesture {
                        // Tap to retry
                        Logger.imageLoader.info("🔄 Retrying image load...")
                        didFail = false
                        Task {
                            await loadImage()
                        }
                    }
            } else {
                placeholder()
            }
        }
        .onAppear {
            // Load image if not already loaded or if it failed previously (retry)
            if image == nil && !isLoading {
                Task {
                    await loadImage()
                }
            }
        }
        .onChange(of: url) { _, newURL in
            // Reset state when URL changes
            if newURL != nil {
                image = nil
                didFail = false
                isLoading = false
            }
        }
        .onChange(of: networkMonitor.isConnected) { wasConnected, isNowConnected in
            // Retry loading if network is restored and image previously failed
            if !wasConnected && isNowConnected && didFail && !isLoading {
                Logger.imageLoader.info("🔄 Network restored, retrying failed image...")
                didFail = false
                Task {
                    await loadImage()
                }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else {
            Logger.imageLoader.warning("⚠️ CachedAsyncImage: No URL provided")
            return
        }
        guard !isLoading else {
            Logger.imageLoader.debug("⏭️ CachedAsyncImage: Already loading")
            return
        }

        isLoading = true
        didFail = false

        do {
            let data = try await imageLoader.loadImage(from: url.absoluteString)
            if let downloadedImage = UIImage(data: data) {
                self.image = downloadedImage
            } else {
                didFail = true
                Logger.imageLoader.error("❌ Failed to create UIImage from data")
            }
        } catch {
            didFail = true
            Logger.imageLoader.error("❌ Image load failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = { ProgressView() }
        self.failure = failure
    }
}
