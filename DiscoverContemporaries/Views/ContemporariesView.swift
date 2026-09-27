import SwiftUI

struct ContemporariesView: View {
    let figure: HistoricalFigure

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text(figure.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                // TODO: Populate this from Wikidata lifespan data once contemporaries discovery is implemented.
                Text("Contemporaries discovery is not implemented for Wikidata figures yet.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 26)
        }
        .background(Color.appBackground)
        .navigationTitle("Contemporaries")
        .navigationBarTitleDisplayMode(.inline)    }
}
