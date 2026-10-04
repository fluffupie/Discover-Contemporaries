import SwiftUI

struct SearchAndCompareView: View {
    let firstFigure: HistoricalFigure

    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var results: [WikidataSearchResult] = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        List {
            Section(footer: footerText) {
                VStack(alignment: .leading, spacing: 10) {
                    SearchField(searchText: $searchText)
                        .onSubmit { performSearch() }
                        .onChange(of: searchText) { oldValue, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            searchTask?.cancel()
                            if trimmed.isEmpty {
                                results = []
                                errorMessage = nil
                                isLoading = false
                            } else {
                                searchTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    if !Task.isCancelled { performSearch() }
                                }
                            }
                        }

                    Button(action: { performSearch() }) {
                        Label("Search", systemImage: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.tealButton)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !results.isEmpty {
                Section(header: Text("Search results")) {
                    ForEach(results) { result in
                        NavigationLink {
                            LifespanCompareView(
                                firstFigure: firstFigure,
                                secondFigure: mapResultToFigure(result)
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.label)
                                    .font(.headline)

                                if let description = result.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search to Compare")
    }

    private var footerText: some View {
        Text("Search any figure to compare with \(firstFigure.name).")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        WikidataAPI.fetchFigures(query: trimmed) { newResults in
            self.isLoading = false
            self.results = newResults
            if newResults.isEmpty {
                self.errorMessage = "No results found."
            }
        }
    }

    private func mapResultToFigure(_ result: WikidataSearchResult) -> HistoricalFigure {
        HistoricalFigure(
            id: result.id,
            name: result.label,
            descriptionText: result.description,
            gender: nil,
            birthPlace: nil,
            birthDate: nil,
            deathDate: nil,
            occupations: [],
            movements: [],
            imageURL: nil,
            imageName: nil
        )
    }
}

#Preview {
    NavigationStack {
        SearchAndCompareView(firstFigure: HistoricalFigure(
            id: "Q762",
            name: "Leonardo da Vinci",
            descriptionText: "Renaissance polymath",
            gender: nil,
            birthPlace: "Vinci, Republic of Florence",
            birthDate: Date(timeIntervalSince1970: -14919744000),
            deathDate: Date(timeIntervalSince1970: -14832288000),
            occupations: ["Artist", "Inventor"],
            movements: ["Renaissance"],
            imageURL: nil,
            imageName: "da-vinci"
        ))
    }
}
