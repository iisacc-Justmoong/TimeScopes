//
//  ThisYearDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct ThisYearDetailView: View {
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
            let startOfNextYear = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1)) ?? now
            let daysInYear = dateProvider.daysInYear(for: now)
            let elapsedDays = max(0, calendar.dateComponents([.day], from: startOfYear, to: dateProvider.startOfDay(for: now)).day ?? 0)
            let remainingDays = max(0, daysInYear - elapsedDays)
            let remainingSecondsTotal = max(0, Int(startOfNextYear.timeIntervalSince(now)))
            let remainingHours = remainingSecondsTotal / 3_600
            let remainingMinutes = remainingSecondsTotal / 60

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Year")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(remainingDays) days left")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                        Text("Elapsed \(elapsedDays) of \(daysInYear) days")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Gauge(value: Double(elapsedDays), in: 0...Double(max(1, daysInYear))) {
                        Text("\(elapsedDays)")
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(Color.accentColor)
                    .labelsHidden()

                    ProgressHeatmapView(
                        totalCells: daysInYear,
                        filledCells: elapsedDays
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remaining (Countdown)")
                            .font(.headline)
                        RemainingTimeRow(title: "Hours", value: remainingHours, unit: "hours")
                        RemainingTimeRow(title: "Minutes", value: remainingMinutes, unit: "minutes")
                        RemainingTimeRow(title: "Seconds", value: remainingSecondsTotal, unit: "seconds")
                    }

                    Spacer(minLength: 12)
                }
                .padding()
            }
            .glassScreen()
            .navigationTitle("This Year")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

}

private struct RemainingTimeRow: View {
    let title: String
    let value: Int
    let unit: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer()
            Text("\(value) \(unit)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    NavigationStack {
        ThisYearDetailView()
    }
}
