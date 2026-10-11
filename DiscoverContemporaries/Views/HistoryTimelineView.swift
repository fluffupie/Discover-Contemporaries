//
//  TimelineView.swift
//  a1
//
//  Created by Hengly Lim on 6/10/2026.
//

import SwiftUI

struct HistoryTimelineView: View {
    
    /// The view model responsible for timeline layout, selection, and zooming.
    @StateObject private var model: TimelineViewModel
    
    /// Creates a historical timeline using the provided figures.
    ///
    /// - Parameters:
    ///   - figures: The historical figures to display on the timeline.
    ///   - highlightedID: An optional identifier of a figure to highlight.
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
        GeometryReader { viewport in
            ZStack(alignment: .topLeading) {
                ForEach(model.ticks) { tick in
                    let x = model.xOffset(forYear: tick.year)
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1, height: model.contentHeight)
                        .offset(x: x)
                        .accessibilityHidden(true)
                    
                    Text(tick.label)
                        .font(.caption2)
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize()
                        .offset(x: x + 4, y: 4)
                        .accessibilityHidden(true)
                }
                
                Color.clear
                    .frame(height: 0.1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Timeline scale")
                    .accessibilityValue(model.visibleRangeText)
                
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
            .offset(model.offset)
            .frame(
                width: viewport.size.width,
                height: viewport.size.height,
                alignment: .topLeading
            )
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(canvasGesture)
            .overlay(alignment: .bottom) {
                visibleRangeLabel
            }
            .onChange(of: viewport.size, initial: true) { _, size in
                model.viewportSize = size
            }
            .animation(.easeInOut(duration: 0.2), value: model.selectedID)
        }
    }
    
    // Gesture
    private var canvasGesture: some Gesture {
        let zoom = MagnifyGesture()
        .onChanged {
            print("pinch", $0.magnification)   // temporary
            model.pinchChanged($0.magnification, around: $0.startLocation)
        }
        .onEnded { _ in model.pinchEnded() }

        let pan = DragGesture(minimumDistance: 8)
        .onChanged {
            print("pan", $0.translation)       // temporary
            model.panChanged($0.translation)
        }
        .onEnded { _ in model.panEnded() }
        
        let doubleTap = SpatialTapGesture(count: 2)
            .onEnded { value in
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let entry = model.entry(at: value.location) {
                        model.zoom(to: entry)
                    } else {
                        model.reset()
                    }
                }
            }
        
        return zoom
            .simultaneously(with: pan)
            .simultaneously(with: doubleTap)
    }
    
    // Feedback
    private var visibleRangeLabel: some View {
        Text(model.visibleRangeText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.9), in: Capsule())
            .padding(.bottom, 8)
            .accessibilityHidden(true)
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
        .accessibilityHint("Select to show details and navigate to profile")
    }
}

/// A footer containing the selected figure's details and timeline zoom controls.
private struct TimelineFooter: View {

    /// The observed view model providing selection and zoom state.
    @ObservedObject var model: TimelineViewModel
    let availableWidth: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            if let entry = model.selectedEntry {
                SelectedFigureCard(entry: entry)
            } else {
                Text("Tap a bar for details. Pinch to zoom, drag to pan, double-tap a bar to focus it or empty space to reset.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .accessibilityLabel("Timeline instructions")
                    .accessibilityValue("Tap a bar for details. Pinch to zoom, drag to pan, double-tap a bar to focus it or empty space to reset.")
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
                .font(.subheadline.weight(.semibold))
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
                        .font(.subheadline.weight(.semibold))
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
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(entry.figure.name)
            .accessibilityValue(entry.yearRangeText)
            .accessibilityHint("Opens profile")
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.secondaryText)

            Text("Nothing to show yet")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Text("None of these figures have birth dates.")
                .font(.caption2)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No timeline data")
        .accessibilityHint("None of the selected figures have birth dates.")
    }
}

#Preview {
    /// - Parameter year: The year used to construct the date.
       /// - Returns: A date representing January 1 of the specified year.
    func date(_ year: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    /// Creates a sample historical figure for the timeline preview.
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
