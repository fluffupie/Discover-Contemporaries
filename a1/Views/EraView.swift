import SwiftUI

struct EraView: View {
    private let controller = FiguresController.shared

    private var eras: [(name: String, count: Int)] {
        Dictionary(grouping: controller.figures, by: \.era)
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(eras, id: \.name) { era in
                CategoryListRow(
                    icon: "calendar",
                    title: era.name,
                    detail: "\(era.count) \(era.count == 1 ? "figure" : "figures")"
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .h1NavigationTitle("Era")
    }
}
