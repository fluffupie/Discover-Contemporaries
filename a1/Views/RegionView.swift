import SwiftUI

struct RegionView: View {
    private let controller = FiguresController.shared

    var body: some View {
        VStack(spacing: 16) {
            ForEach(controller.regions) { region in
                HStack(spacing: 14) {
                    Text(region.flag)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(region.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primaryText)
                        Text(region.count)
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .h1NavigationTitle("Region")
    }
}
