import SwiftUI

struct JobsView: View {
    private let controller = FiguresController.shared

    private var jobs: [(name: String, count: Int)] {
        Dictionary(grouping: controller.figures, by: \.role)
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(jobs, id: \.name) { job in
                CategoryListRow(
                    icon: "briefcase.fill",
                    title: job.name,
                    detail: "\(job.count) \(job.count == 1 ? "figure" : "figures")"
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .h1NavigationTitle("Jobs")
    }
}
