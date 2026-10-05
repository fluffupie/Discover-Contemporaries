import SwiftUI

struct BookmarkView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Image(systemName: "heart")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.secondaryText)

                Text("Saved figures")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text("Your bookmarked profiles will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)

                EmptySearchView()
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .navigationTitle("Saves")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BookmarkView()
    }
}
