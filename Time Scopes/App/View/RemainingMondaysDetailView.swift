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

            let totalMondays = mondayCount(from: startOfYear, to: endOfYear, calendar: calendar)
            let mondaysPassed = mondayCount(from: startOfYear, to: now, calendar: calendar)
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
                ]
            ) {
                ProgressHeatmapView(
                    totalCells: totalMondays,
                    filledCells: mondaysPassed
                )
            }
        }
    }

    private func mondayCount(from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        if endDay < startDay {
            return 0
        }

        let startWeekday = calendar.component(.weekday, from: startDay)
        let daysToMonday = (2 - startWeekday + 7) % 7
        guard let firstMonday = calendar.date(byAdding: .day, value: daysToMonday, to: startDay) else {
            return 0
        }
        if firstMonday > endDay {
            return 0
        }

        let daysBetween = calendar.dateComponents([.day], from: firstMonday, to: endDay).day ?? 0
        return daysBetween / 7 + 1
    }

    private func lastMondayInYear(_ endOfYear: Date, calendar: Calendar) -> Date {
        let endDay = calendar.startOfDay(for: endOfYear)
        let weekday = calendar.component(.weekday, from: endDay)
        let daysSinceMonday = (weekday - 2 + 7) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: endDay) ?? endDay
    }
}

#Preview {
    NavigationStack {
        RemainingMondaysDetailView()
    }
}
