//
//  NextChristmasDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct NextChristmasDetailView: View {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    var body: some View {
        TimelineView(.periodic(from: dateProvider.now(), by: 1)) { timeline in
            let now = timeline.date
            let calendar = dateProvider.calendar
            let currentYear = calendar.component(.year, from: now)
            let christmasThisYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 25)) ?? now
            let targetChristmas = now > christmasThisYear
                ? (calendar.date(from: DateComponents(year: currentYear + 1, month: 12, day: 25)) ?? christmasThisYear)
                : christmasThisYear
            let lastChristmas = now >= christmasThisYear
                ? christmasThisYear
                : (calendar.date(from: DateComponents(year: currentYear - 1, month: 12, day: 25)) ?? now)

            let startOfLastChristmas = calendar.startOfDay(for: lastChristmas)
            let startOfTargetChristmas = calendar.startOfDay(for: targetChristmas)
            let startOfToday = calendar.startOfDay(for: now)

            let totalDaysBetween = max(
                1,
                calendar.dateComponents([.day], from: startOfLastChristmas, to: startOfTargetChristmas).day ?? 0
            )
            let elapsedDays = max(
                0,
                calendar.dateComponents([.day], from: startOfLastChristmas, to: startOfToday).day ?? 0
            )
            let remainingDays = max(0, totalDaysBetween - elapsedDays)

            let remainingSeconds = max(0, Int(targetChristmas.timeIntervalSince(now)))
            let remainingHours = remainingSeconds / 3_600
            let remainingMinutes = remainingSeconds / 60

            EventDetailView(
                title: "Next Christmas :",
                count: remainingDays,
                unit: "days",
                gauge: EventDetailView.GaugeData(
                    value: elapsedDays,
                    min: 0,
                    max: totalDaysBetween
                ),
                breakdown: [
                    EventDetailView.BreakdownItem(label: "Hours", value: remainingHours, unit: "hours"),
                    EventDetailView.BreakdownItem(label: "Minutes", value: remainingMinutes, unit: "minutes"),
                    EventDetailView.BreakdownItem(label: "Seconds", value: remainingSeconds, unit: "seconds")
                ]
            ) {
                ProgressHeatmapView(
                    totalCells: totalDaysBetween,
                    filledCells: elapsedDays
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        NextChristmasDetailView()
    }
}
