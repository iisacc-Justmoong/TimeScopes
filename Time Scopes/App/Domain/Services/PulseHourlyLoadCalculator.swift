//
//  PulseHourlyLoadCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation

enum PulseHourlyLoadCalculator {
    struct Span {
        let start: Date
        let end: Date
    }

    static func makeSeries(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent,
        eventSpans: [Span],
        reminderSpans: [Span],
        reminderMoments: [Date]
    ) -> [Double] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let dayInterval = DateInterval(start: dayStart, end: dayEnd)
        var deltas = Array(repeating: 0, count: 25)

        for span in eventSpans {
            apply(span: span, in: dayInterval, dayStart: dayStart, deltas: &deltas)
        }
        for span in reminderSpans {
            apply(span: span, in: dayInterval, dayStart: dayStart, deltas: &deltas)
        }
        for moment in reminderMoments {
            apply(moment: moment, in: dayInterval, dayStart: dayStart, deltas: &deltas)
        }

        var series = Array(repeating: 0.0, count: 24)
        var running = 0
        for hour in 0..<24 {
            running += deltas[hour]
            series[hour] = Double(running)
        }
        return series
    }

    private static func apply(
        span: Span,
        in dayInterval: DateInterval,
        dayStart: Date,
        deltas: inout [Int]
    ) {
        let start = max(span.start, dayInterval.start)
        let end = min(span.end, dayInterval.end)
        guard end > start else { return }

        let startHour = hourIndex(for: start, dayStart: dayStart, rounding: .down)
        let endHourExclusive = max(
            startHour + 1,
            hourIndex(for: end, dayStart: dayStart, rounding: .up)
        )

        deltas[startHour] += 1
        deltas[endHourExclusive] -= 1
    }

    private static func apply(
        moment: Date,
        in dayInterval: DateInterval,
        dayStart: Date,
        deltas: inout [Int]
    ) {
        guard moment >= dayInterval.start && moment < dayInterval.end else { return }
        let hour = hourIndex(for: moment, dayStart: dayStart, rounding: .down)
        deltas[hour] += 1
        deltas[hour + 1] -= 1
    }

    private static func hourIndex(
        for date: Date,
        dayStart: Date,
        rounding: FloatingPointRoundingRule
    ) -> Int {
        let raw = date.timeIntervalSince(dayStart) / 3_600
        let rounded: Double
        switch rounding {
        case .up:
            rounded = raw.rounded(.up)
        default:
            rounded = raw.rounded(.down)
        }
        return max(0, min(24, Int(rounded)))
    }
}
