//
//  MediaLinkCard.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import SwiftUI

/// Card component displaying a media link/asset with preview image and metadata
struct MediaLinkCard: View {

    let link: MediaLinkViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview image
            if let url = link.href {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } failure: {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .frame(height: 150)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Link metadata
            VStack(alignment: .leading, spacing: 4) {
                if let rel = link.rel {
                    HStack {
                        Text("Type:")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(rel.capitalized)
                    }
                    .font(.caption)
                }

                if let render = link.render {
                    HStack {
                        Text("Format:")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(render.capitalized)
                    }
                    .font(.caption)
                }

                HStack {
                    Text("Dimensions:")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("\(link.width) × \(link.height)")
                }
                .font(.caption)

                HStack {
                    Text("Size:")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(formatFileSize(link.size))
                }
                .font(.caption)

                if let url = link.href {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("View in Browser")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

}

// MARK: - Previews

#Preview {
    MediaLinkCard(link: MediaLinkViewState(
        id: "1",
        href: URL(string: "https://images-assets.nasa.gov/image/PIA12345/PIA12345~thumb.jpg"),
        rel: "preview",
        render: "image",
        width: 800,
        height: 600,
        size: 250000
    ))
    .padding()
}
