//
//  TimeScopeHeatmapDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-01-25.
//

import SwiftUI

struct TimeScopeHeatmapDetailView: View {
    enum Unit {
        case month
        case week
        case day

        var title: String {
            switch self {
            case .month:
                return "Months"
            case .week:
                return "Weeks"
            case .day:
                return "Days"
            }
        }

        var unitLabel: String {
            switch self {
            case .month:
                return "months"
            case .week:
                return "weeks"
            case .day:
                return "days"
            }
        }
    }

    @EnvironmentObject var userData: UserData
    private let dateProvider: DateProviding
    let unit: Unit

    init(unit: Unit, dateProvider: DateProviding = SystemDateProvider()) {
        self.unit = unit
        self.dateProvider = dateProvider
    }

    var body: some View {
        let startDate = userData.birthday
        let endDate = userData.deathDate
        let now = dateProvider.now()
        let clampedNow = min(max(now, startDate), endDate)

        let totalDays = daysBetween(startDate, endDate)
        let elapsedDays = daysBetween(startDate, clampedNow)
        let totalMonths = monthsBetween(startDate, endDate)
        let elapsedMonths = monthsBetween(startDate, clampedNow)
        let totalWeeks = (totalDays + 6) / 7

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(unit.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Elapsed \(elapsedCount(totalDays: totalDays, totalMonths: totalMonths, elapsedDays: elapsedDays, elapsedMonths: elapsedMonths)) of \(totalCount(totalDays: totalDays, totalMonths: totalMonths)) \(unit.unitLabel)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                switch unit {
                case .month:
                    monthGrid(totalMonths: totalMonths, elapsedMonths: elapsedMonths)
                case .week:
                    weekGrid(totalWeeks: totalWeeks, elapsedDays: elapsedDays)
                case .day:
                    dayGrid(totalDays: totalDays, elapsedDays: elapsedDays)
                }

                Spacer(minLength: 12)
            }
            .padding()
        }
        .glassScreen()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func elapsedCount(totalDays: Int, totalMonths: Int, elapsedDays: Int, elapsedMonths: Int) -> Int {
        switch unit {
        case .month:
            return elapsedMonths
        case .week:
            return elapsedDays / 7
        case .day:
            return elapsedDays
        }
    }

    private func totalCount(totalDays: Int, totalMonths: Int) -> Int {
        switch unit {
        case .month:
            return totalMonths
        case .week:
            return (totalDays + 6) / 7
        case .day:
            return totalDays
        }
    }

    private func monthGrid(totalMonths: Int, elapsedMonths: Int) -> some View {
        let columns = [GridItem(.adaptive(minimum: Layout.cellSize, maximum: Layout.cellSize), spacing: Layout.cellSpacing)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(0..<totalMonths, id: \.self) { index in
                GrassCell(isFilled: index < elapsedMonths)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weekGrid(totalWeeks: Int, elapsedDays: Int) -> some View {
        let columns = [GridItem(.adaptive(minimum: Layout.cellSize, maximum: Layout.cellSize), spacing: Layout.cellSpacing)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(0..<totalWeeks, id: \.self) { index in
                let isFilled = elapsedDays > index * 7
                GrassCell(isFilled: isFilled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayGrid(totalDays: Int, elapsedDays: Int) -> some View {
        let columns = [GridItem(.adaptive(minimum: Layout.cellSize, maximum: Layout.cellSize), spacing: Layout.cellSpacing)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(0..<totalDays, id: \.self) { index in
                GrassCell(isFilled: index < elapsedDays)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = dateProvider.calendar
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return max(0, calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
    }

    private func monthsBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = dateProvider.calendar
        return max(0, calendar.dateComponents([.month], from: start, to: end).month ?? 0)
    }
}

private struct GrassCell: View {
    let isFilled: Bool
    var isHidden: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isFilled ? Color.blue : Color.blue.opacity(0.18))
            .frame(width: Layout.cellSize, height: Layout.cellSize)
            .opacity(isHidden ? 0 : 1)
    }
}

private enum Layout {
    static let cellSize: CGFloat = 12
    static let cellSpacing: CGFloat = 4
}

#Preview {
    NavigationStack {
        TimeScopeHeatmapDetailView(unit: .day)
            .environmentObject(UserData())
    }
}
