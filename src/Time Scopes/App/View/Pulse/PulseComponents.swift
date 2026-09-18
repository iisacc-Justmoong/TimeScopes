//
//  PulseComponents.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct PulseSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct PulseSummaryCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

struct PulseWeeklyEventRow: View {
    let event: PulseWeeklyEvent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(event.day)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            Text(event.title)
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(PulseFormatters.formatDuration(event.duration))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

struct WeeklyRhythmChart: View {
    let days: [PulseDayIntensity]
    let highlightDay: String

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let spacing: CGFloat = 8
                let count = max(1, days.count)
                let totalSpacing = spacing * CGFloat(max(0, count - 1))
                let barWidth = max(10, (proxy.size.width - totalSpacing) / CGFloat(count))

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(days) { day in
                        let isHighlight = day.day == highlightDay
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isHighlight ? Color.green : Color.accentColor.opacity(0.75))
                                .frame(width: barWidth, height: max(16, 110 * day.intensity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                )
                            Text(day.day)
                                .font(.caption2)
                                .foregroundStyle(isHighlight ? Color.green : .secondary)
                                .frame(width: barWidth, alignment: .center)
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
            }
            .frame(height: 140)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }
}

struct PulseDayLineChart: View {
    let values: [Double]
    let maxValue: Double
    let currentFraction: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let count = max(2, values.count)
            let maxLoad = max(1, maxValue)
            let step = width / CGFloat(count - 1)

            Path { path in
                for index in 0..<count {
                    let x = CGFloat(index) * step
                    let yValue = values[index]
                    let normalized = min(1, yValue / maxLoad)
                    let y = height - CGFloat(normalized) * height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.accentColor, lineWidth: 2)

            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                for index in 0..<count {
                    let x = CGFloat(index) * step
                    let yValue = values[index]
                    let normalized = min(1, yValue / maxLoad)
                    let y = height - CGFloat(normalized) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(Color.accentColor.opacity(0.12))

            let clamped = min(1, max(0, currentFraction))
            let currentX = clamped * width
            Path { path in
                path.move(to: CGPoint(x: currentX, y: 0))
                path.addLine(to: CGPoint(x: currentX, y: height))
            }
            .stroke(Color.primary.opacity(0.35), lineWidth: 1)

            HStack {
                Text("0")
                Spacer()
                Text("6")
                Spacer()
                Text("12")
                Spacer()
                Text("18")
                Spacer()
                Text("24")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, height - 16)
        }
    }
}

struct PulsePrescriptionRow: View {
    let prescription: PulsePrescription

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PulseTag(text: prescription.focus)
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(prescription.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(prescription.impact)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct PulseTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.2))
            )
            .foregroundStyle(Color.accentColor)
    }
}

struct PulseCallout: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.callout)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

struct PulseJournalRow: View {
    let entry: PulseJournalEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PulseFormatters.shortDateFormatter.string(from: entry.date))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(PulseFormatters.timeFormatter.string(from: entry.date))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text(entry.note)
                .font(.callout)
                .lineLimit(2)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            VStack {
                Spacer(minLength: 0)
                Menu {
                    Button("Edit") {
                        onEdit()
                    }
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

struct PulseJournalQuickEntry: View {
    @Binding var draft: String
    let onSave: (String) -> Void

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                    )
                if draft.isEmpty {
                    Text("Write today's entry")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
            HStack {
                Spacer()
                Button("Save Entry") {
                    onSave(trimmedDraft)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .disabled(trimmedDraft.isEmpty)
            }
        }
    }
}

struct PulseJournalComposer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let saveLabel: String
    @Binding var draft: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $draft)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                    )
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveLabel) {
                        onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
