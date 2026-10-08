//
//  TimelineView.swift
//  a1
//
//  Created by Hengly Lim on 6/10/2026.
//

import SwiftUI

struct HistoryTimelineView: View {

    @StateObject private var model: TimelineViewModel

    init(
        figures: [HistoricalFigure],
        highlightedID: String? = nil
    ) {
        _model = StateObject(
            wrappedValue: TimelineViewModel(
                figures: figures,
                highlightedID: highlightedID
            )
        )
    }

    var body: some View {
        Group {
            if model.entries.isEmpty {
                EmptyTimelineView()
            } else {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        canvas

                        Divider()

                        TimelineFooter(
                            model: model,
                            availableWidth: proxy.size.width
                        )
                    }
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Canvas
    private var canvas: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                ForEach(model.ticks) { tick in
                    let x = model.xOffset(forYear: tick.year)

                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1, height: model.contentHeight)
                        .offset(x: x)

                    Text(tick.label)
                        .font(.caption2)
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize()
                        .offset(x: x + 4, y: 4)
                }

                ForEach(model.entries) { entry in
                    TimelineBar(
                        entry: entry,
                        width: model.width(for: entry),
                        isHighlighted: entry.id == model.highlightedID,
                        isSelected: entry.id == model.selectedID
                    ) {
                        model.select(entry)
                    }
                    .offset(
                        x: model.xOffset(for: entry),
                        y: model.yOffset(for: entry)
                    )
                }
            }
            .frame(
                width: model.totalWidth,
                height: model.contentHeight,
                alignment: .topLeading
            )
        }
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { model.pinchChanged($0.magnification) }
                .onEnded { _ in model.pinchEnded() }
        )
        .animation(.easeInOut(duration: 0.2), value: model.selectedID)
    }
}

// Bar
private struct TimelineBar: View {

    let entry: TimelineEntry
    let width: CGFloat
    let isHighlighted: Bool
    let isSelected: Bool
    let action: () -> Void

    private var fill: Color {
        if isSelected {
            return Color.peach.opacity(0.45)
        }
        if isHighlighted {
            return Color.minty
        }
        return Color.minty.opacity(0.22)
    }

    var body: some View {
        Button(action: action) {
            Text(entry.figure.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    isHighlighted && !isSelected
                        ? Color.white
                        : Color.primaryText
                )
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(
                    width: width,
                    height: TimelineViewModel.rowHeight,
                    alignment: .leading
                )
                .background(fill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            Color.peach,
                            lineWidth: isSelected ? 2 : 0
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(entry.figure.name), \(entry.yearRangeText)"
        )
    }
}

// Footer

private struct TimelineFooter: View {

    @ObservedObject var model: TimelineViewModel
    let availableWidth: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            if let entry = model.selectedEntry {
                SelectedFigureCard(entry: entry)
            } else {
                Text("Tap a bar for details. Pinch or use the buttons to zoom.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            if model.skippedCount > 0 {
                Text("\(model.skippedCount) without birth dates not shown")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
            }

            HStack(spacing: 12) {
                zoomButton("minus.magnifyingglass", label: "Zoom out") {
                    model.zoomOut()
                }

                zoomButton("arrow.left.and.right", label: "Fit all") {
                    model.fit(toWidth: availableWidth)
                }

                zoomButton("plus.magnifyingglass", label: "Zoom in") {
                    model.zoomIn()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    private func zoomButton(
        _ systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .background(Color.minty)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct SelectedFigureCard: View {

    let entry: TimelineEntry

    var body: some View {
        NavigationLink {
            ProfileView(figure: entry.figure)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.figure.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    Text(entry.yearRangeText)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    if let description = entry.figure.descriptionText {
                        Text(description)
                            .font(.caption2)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(12)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.secondaryText)

            Text("Nothing to show yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primaryText)

            Text("None of these figures have birth dates.")
                .font(.caption2)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    func date(_ year: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    func figure(
        _ id: String,
        _ name: String,
        _ birth: Int,
        _ death: Int?
    ) -> HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: nil,
            gender: nil,
            birthPlace: nil,
            birthDate: date(birth),
            deathDate: death.map(date),
            occupations: [],
            movements: [],
            imageURL: nil,
            imageName: nil
        )
    }

    return NavigationStack {
        HistoryTimelineView(
            figures: [
                figure("Q762", "Leonardo da Vinci", 1452, 1519),
                figure("Q7259", "Ada Lovelace", 1815, 1852),
                figure("Q9682", "Elizabeth II", 1926, 2022),
                figure("Q2831", "Michael Jackson", 1958, 2009)
            ],
            highlightedID: "Q7259"
        )
    }
}
