import SwiftUI

struct EraView: View {
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Replace with Wikidata-derived era grouping when full figure dates are loaded.
            Text("")

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .navigationTitle("Eras")
        .navigationBarTitleDisplayMode(.inline)
    }
}
