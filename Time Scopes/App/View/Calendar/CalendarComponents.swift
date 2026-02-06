//
//  CalendarComponents.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct CalendarDayCell: View {
    let day: Int
    let isSelected: Bool
    let isToday: Bool
    let markers: [CalendarMarker]
    let overflowCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                if !markers.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(markers) { marker in
                            Circle()
                                .fill(marker.color)
                                .frame(width: 4, height: 4)
                        }
                        if overflowCount > 0 {
                            Text("+")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InsightRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JumpDatePicker: View {
    @Binding var jumpDate: Date
    @Binding var sheetHeight: CGFloat
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Go to Date")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    onDone()
                }
                .font(.callout)
            }

            DatePicker(
                "Go to Date",
                selection: $jumpDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
        .padding()
        .background(Color.clear)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(SheetHeightKey.self) { value in
            let clamped = max(360, value)
            if abs(sheetHeight - clamped) > 1 {
                sheetHeight = clamped
            }
        }
    }
}

enum SheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct AgendaItemRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(spacing: 8) {
            if item.kind == .reminder {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(item.color)
            } else if item.kind == .journal {
                Image(systemName: "note.text")
                    .foregroundStyle(item.color)
            } else {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
            }
            Text(item.title)
                .font(.callout)
            Spacer()
            Text(timeLabel(for: item))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func timeLabel(for item: AgendaItem) -> String {
        if item.isAllDay {
            return "All day"
        }
        let formatter = CalendarView.timeFormatter
        if item.kind == .reminder || item.kind == .journal {
            return formatter.string(from: item.startDate)
        }
        return "\(formatter.string(from: item.startDate)) - \(formatter.string(from: item.endDate))"
    }
}

struct AgendaMonthRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(spacing: 12) {
            if item.kind == .reminder {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(item.color)
            } else if item.kind == .journal {
                Image(systemName: "note.text")
                    .foregroundStyle(item.color)
            } else {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.callout)
                Text(item.startDate, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.isAllDay {
                    Text(timeRange(for: item))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private func timeRange(for item: AgendaItem) -> String {
        let formatter = CalendarView.timeFormatter
        if item.kind == .reminder || item.kind == .journal {
            return formatter.string(from: item.startDate)
        }
        return "\(formatter.string(from: item.startDate)) - \(formatter.string(from: item.endDate))"
    }
}
