//
//  RemainingMondaysDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct RemainingMondaysDetailView: View {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    var body: some View {
        TimelineView(.periodic(from: dateProvider.now(), by: 1)) { timeline in
            let now = timeline.date
            let calendar = dateProvider.calendar
            let currentYear = calendar.component(.year, from: now)
            let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) ?? now
            let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) ?? now

            let totalMondays = mondaysBetween(startOfYear, endOfYear, calendar: calendar)
            let mondaysPassed = mondaysBetween(startOfYear, now, calendar: calendar)
            let remainingMondays = max(0, totalMondays - mondaysPassed)

            let lastMonday = lastMondayInYear(endOfYear, calendar: calendar)
            let lastMondayStart = calendar.startOfDay(for: lastMonday)
            let remainingSeconds = max(0, Int(lastMondayStart.timeIntervalSince(now)))
            let remainingHours = remainingSeconds / 3_600
            let remainingMinutes = remainingSeconds / 60

            EventDetailView(
                title: "Remining Mondays :",
                count: remainingMondays,
                unit: "times",
                gauge: EventDetailView.GaugeData(
                    value: mondaysPassed,
                    min: 0,
                    max: max(1, totalMondays)
                ),
                breakdown: [
                    EventDetailView.BreakdownItem(label: "Hours", value: remainingHours, unit: "hours"),
                    EventDetailView.BreakdownItem(label: "Minutes", value: remainingMinutes, unit: "minutes"),
                    EventDetailView.BreakdownItem(label: "Seconds", value: remainingSeconds, unit: "seconds")
                ],
                extraContent: AnyView(
                    ProgressHeatmapView(
                        totalCells: totalMondays,
                        filledCells: mondaysPassed
                    )
                )
            )
        }
    }

    private func mondaysBetween(_ startDate: Date, _ endDate: Date, calendar: Calendar) -> Int {
        var count = 0
        var date = calendar.startOfDay(for: startDate)
        let end = endDate

        while date <= end {
            if calendar.component(.weekday, from: date) == 2 {
                count += 1
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return count
    }

    private func lastMondayInYear(_ endOfYear: Date, calendar: Calendar) -> Date {
        var date = calendar.startOfDay(for: endOfYear)
        while calendar.component(.weekday, from: date) != 2 {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }
}

#Preview {
    NavigationStack {
        RemainingMondaysDetailView()
    }
}
