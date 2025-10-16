//
//  MediaItemRow.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import SwiftUI

struct MediaItemRow: View {

    let item: MediaItemViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let center = item.center {
                    Text(center)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }

                // Asset count badge
                HStack {
                    Image(systemName: "photo.stack")
                        .font(.caption2)
                    Text("\(item.assetCount) asset\(item.assetCount == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), from \(item.center ?? "Unknown"), \(item.assetCount) assets")
    }

    private var thumbnail: some View {
        Group {
            if let url = item.thumbnailURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } failure: {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}

// MARK: - Previews

#Preview("With Thumbnail") {
    List {
        MediaItemRow(item: .mock())
        MediaItemRow(item: .mock(
            title: "Apollo 11 Moon Landing",
            center: "KSC",
            description: "Historic moment as Neil Armstrong and Buzz Aldrin became the first humans to walk on the Moon.",
            assetCount: 12
        ))
    }
}

#Preview("Without Thumbnail") {
    List {
        MediaItemRow(item: .mock(
            title: "International Space Station",
            center: nil,
            description: nil,
            assetCount: 1,
            thumbnailURL: nil
        ))
    }
}

#Preview("Long Text") {
    List {
        MediaItemRow(item: .mock(
            title: "This is a very long title that should truncate after two lines of text to maintain proper layout",
            description: "This is a very long description that should also truncate after two lines to prevent the row from becoming too tall and maintain a clean list appearance"
        ))
    }
}
