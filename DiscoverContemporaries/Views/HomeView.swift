import SwiftUI

struct HomeView: View {

    @StateObject private var model = FigureViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView()

                SearchField(searchText: $model.searchText).onSubmit {
                    model.searchFigures()
                }

                Text(
                    model.searchText.isEmpty
                        ? "Explore figures"
                        : "Search results"
                )
                .font(.h1SectionTitle)
                .tracking(1.1)
                .foregroundStyle(Color.primaryText)

                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)

                } else if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)

                } else if !model.searchResults.isEmpty {

                    VStack(spacing: 12) {

                        ForEach(model.searchResults) { result in
                            WikidataSearchResultRow(result: result)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }
}

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Who lived at\nthe same time?")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(1)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)

            Text("Explore history through overlapping lifespans.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.secondaryText)
                .padding(.top, 2)
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

private struct WikidataSearchResultRow: View {

    let result: WikidataSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(result.label)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            if let description = result.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            Text(result.id)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}
