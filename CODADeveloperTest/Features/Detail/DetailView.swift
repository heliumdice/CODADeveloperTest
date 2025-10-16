//
//  DetailView.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import SwiftUI

struct DetailView: View {
    let item: MediaItemViewState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header image
                if let url = item.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                                .frame(height: 250)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                }

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Metadata
                    if let center = item.center {
                        metadataRow(label: "Center", value: center)
                    }

                    if let dateCreated = item.dateCreated {
                        metadataRow(label: "Date", value: formatDate(dateCreated))
                    }

                    metadataRow(label: "NASA ID", value: item.nasaID)

                    // Description
                    if let description = item.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(description)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Assets section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assets")
                            .font(.headline)

                        if item.assetCount > 0 {
                            Text("\(item.assetCount) media asset\(item.assetCount == 1 ? "" : "s") available")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No assets available")
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Views

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Full Details") {
    NavigationStack {
        DetailView(item: .mock())
    }
}

#Preview("Minimal Details") {
    NavigationStack {
        DetailView(item: .mock(
            title: "Test Item",
            center: nil,
            description: nil,
            assetCount: 0,
            thumbnailURL: nil,
            dateCreated: nil
        ))
    }
}

#Preview("Long Description") {
    NavigationStack {
        DetailView(item: .mock(
            description: """
            This is a much longer description that spans multiple lines to demonstrate how the detail view \
            handles extensive text content. The description should wrap properly and maintain good readability \
            while providing comprehensive information about the media item. This helps users understand the \
            context and significance of the NASA media they're viewing.
            """
        ))
    }
}
