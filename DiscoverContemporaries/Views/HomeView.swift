import SwiftUI

struct HomeView: View {
    @StateObject var model = FigureViewModel()

    private let controller = FigureViewModel.shared

    private var displayedFigures: [HistoricalFigure] {
        controller.displayedFigures(for: searchText)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView()

                SearchField(searchText: $searchText)

                Text(searchText.isEmpty ? "Explore figures" : "Search results")
                    .font(.h1SectionTitle)
                    .tracking(1.1)
                    .foregroundStyle(Color.primaryText)

                if displayedFigures.isEmpty {
                    EmptySearchView()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                        ForEach(displayedFigures) { figure in
                            NavigationLink {
                                ProfileView(figure: figure)
                            } label: {
                                FigureCard(figure: figure, height: 132)
                            }
                            .buttonStyle(.plain)
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
            Text("HOME")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.secondaryText)

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
