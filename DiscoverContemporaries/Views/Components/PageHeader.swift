import SwiftUI

struct PageHeader: View {
    let title: String
    let showsBackButton: Bool

    @Environment(\.dismiss) private var dismiss

    init(title: String, showsBackButton: Bool = false) {
        self.title = title
        self.showsBackButton = showsBackButton
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.h1PageTitle)
                .tracking(1.2)
                .foregroundStyle(Color.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            if showsBackButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 34, height: 34)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.14), radius: 7, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Back")
            }
        }
        .frame(height: 34)
    }
}
