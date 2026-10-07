import SwiftUI

struct RegionView: View {

    private let continents = [
        Continent(id: "Q15", name: "Africa"),
        Continent(id: "Q48", name: "Asia"),
        Continent(id: "Q46", name: "Europe"),
        Continent(id: "Q49", name: "North America"),
        Continent(id: "Q18", name: "South America"),
        Continent(id: "Q538", name: "Oceania"),
        Continent(id: "Q51", name: "Antarctica")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(continents) { continent in
                    NavigationLink {
                        ContinentTopFiguresView(
                            continent: continent
                        )
                    } label: {
                        RegionRow(
                            continent: continent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground)
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Region Row

private struct RegionRow: View {

    let continent: Continent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.emerald)
                .frame(width: 44, height: 44)

            Text(continent.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
    }
}
