import SwiftUI

struct PageView: View {

    let figures: [HistoricalFigure]

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            PageViewController(
                pages: figures.map { figure in
                    NavigationLink {
                        ProfileView(figure: figure)
                    } label: {
                        FeatureCard(figure: figure)
                    }
                    .buttonStyle(.plain)
                },
                currentPage: $currentPage
            )

            if figures.count > 1 {
                PageControl(
                    numberOfPages: figures.count,
                    currentPage: $currentPage
                )
                .padding(.trailing, 12)
                .padding(.bottom, 8)
            }
        }
        .aspectRatio(3 / 2, contentMode: .fit)
    }
}
