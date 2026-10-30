//
//  CachedFiguresDebugView.swift
//  DiscoverContemporaries
//
//  Created by Nina Chen on 30/10/2026.
//

import Foundation
import SwiftData
import SwiftUI

struct CachedFiguresDebugView: View {
    // Uses @Query to read CachedHistoricalFigure objects (read-only)
    @Query(sort: \CachedHistoricalFigure.cachedAt, order: .reverse)
    private var cachedFigures: [CachedHistoricalFigure]

    var body: some View {
        NavigationStack {
            Group {
                if cachedFigures.isEmpty {
                    ContentUnavailableView(
                        "No cached figures",
                        systemImage: "tray",
                        description: Text("Cache is empty. Run the app to seed or fetch figures, then revisit this view.")
                    )
                    .padding()
                } else {
                    List(cachedFigures, id: \.wikidataID) { cached in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cached.name)
                                .font(.headline)

                            if let desc = cached.descriptionText, !desc.isEmpty {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            HStack(spacing: 8) {
                                Label(cached.wikidataID, systemImage: "number")
                                    .font(.caption)
                                Spacer(minLength: 8)
                                if let date = cached.cachedAt as Date? {
                                    Text(date.formatted())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(cached.name)
                        .accessibilityValue("Wikidata ID \(cached.wikidataID)")
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Cached Figures")
        }
    }
}

// by default, the preview uses an in-memory container
// to see real cached data:
// run the app to populate the cache
// tamporarily preview using your app's container
#Preview("Cached Figures Debug") {
    // Provide a model container so @Query works in previews.
    // If you have a specific model container setup, replace this with your app’s configuration.
    CachedFiguresDebugView()
        .modelContainer(for: CachedHistoricalFigure.self, inMemory: true)
}
