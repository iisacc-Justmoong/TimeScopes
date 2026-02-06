//
//  WeekdayScopeDetailContent.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct WeekdayScopeDetailContent: View {
    @EnvironmentObject var userData: UserData
    let totalWeekdays: Int
    @ObservedObject var ticker: SecondTicker
    @State private var remainingWorkSeconds: Int = 0
    @State private var remainingWorkSleepSeconds: Int = 0
    @State private var lastTick: Date = Date()

    var body: some View {
        let weeksEquivalent = totalWeekdays / 5
        let monthsEquivalent = totalWeekdays / 21
        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let freeWorkMinutes = remainingWorkSeconds / 60
        let freeWorkHours = remainingWorkSeconds / 3_600

        let freeWorkSleepMinutes = remainingWorkSleepSeconds / 60
        let freeWorkSleepHours = remainingWorkSleepSeconds / 3_600

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekday Conversions")
                    .font(.headline)
                WeekdayDetailRow(title: "Weeks (weekdays)", value: weeksEquivalent, unit: "weeks")
                WeekdayDetailRow(title: "Months (weekdays)", value: monthsEquivalent, unit: "months")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Weekdays, Work \(workHours)h)")
                    .font(.headline)
                WeekdayDetailRow(title: "Hours", value: freeWorkHours, unit: "hours")
                WeekdayDetailRow(title: "Minutes", value: freeWorkMinutes, unit: "minutes")
                WeekdayDetailRow(title: "Seconds", value: remainingWorkSeconds, unit: "seconds")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Weekdays, Work \(workHours)h + Sleep \(sleepHours)h)")
                    .font(.headline)
                WeekdayDetailRow(title: "Hours", value: freeWorkSleepHours, unit: "hours")
                WeekdayDetailRow(title: "Minutes", value: freeWorkSleepMinutes, unit: "minutes")
                WeekdayDetailRow(title: "Seconds", value: remainingWorkSleepSeconds, unit: "seconds")
            }
        }
        .onChange(of: userData.workHoursPerDay) {
            resetCountdown(at: ticker.now)
        }
        .onChange(of: userData.sleepHoursPerDay) {
            resetCountdown(at: ticker.now)
        }
        .onChange(of: userData.deathDate) {
            resetCountdown(at: ticker.now)
        }
        .onAppear {
            resetCountdown(at: ticker.now)
        }
        .onReceive(ticker.$now) { updated in
            let delta = max(0, Int(updated.timeIntervalSince(lastTick).rounded(.down)))
            guard delta > 0 else { return }
            remainingWorkSeconds = max(0, remainingWorkSeconds - delta)
            remainingWorkSleepSeconds = max(0, remainingWorkSleepSeconds - delta)
            lastTick = updated
        }
    }

    private func resetCountdown(at date: Date) {
        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let freeWorkHoursPerDay = max(0, 24 - workHours)
        let freeWorkSleepHoursPerDay = max(0, 24 - workHours - sleepHours)

        remainingWorkSeconds = Int(ceil(remainingFreeSeconds(
            from: date,
            to: userData.deathDate,
            freeHoursPerDay: freeWorkHoursPerDay
        )))
        remainingWorkSleepSeconds = Int(ceil(remainingFreeSeconds(
            from: date,
            to: userData.deathDate,
            freeHoursPerDay: freeWorkSleepHoursPerDay
        )))
        lastTick = date
    }

    private func remainingFreeSeconds(from now: Date, to endDate: Date, freeHoursPerDay: Int) -> TimeInterval {
        guard freeHoursPerDay > 0 else { return 0 }
        let calendar = Calendar.autoupdatingCurrent
        let dayInterval = calendar.dateInterval(of: .day, for: now)
        let startDay = calendar.startOfDay(for: now)
        let endDay = calendar.startOfDay(for: endDate)
        guard endDay >= startDay else { return 0 }

        let totalWeekdays = weekdaysBetween(startDay: startDay, endDay: endDay, calendar: calendar)
        let todayIsWeekday = isWeekday(startDay, calendar: calendar)
        let fullFutureWeekdays = max(0, totalWeekdays - (todayIsWeekday ? 1 : 0))

        let dayEnd = dayInterval?.end ?? calendar.date(byAdding: .day, value: 1, to: startDay) ?? startDay
        let endBoundary = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        let effectiveDayEnd = min(dayEnd, endBoundary)
        let remainingSecondsToday = max(0, effectiveDayEnd.timeIntervalSince(now))
        let dayDuration = max(1, dayInterval?.duration ?? 86_400)
        let remainingFractionToday = min(1, remainingSecondsToday / dayDuration)

        let todayFreeSeconds = todayIsWeekday
            ? Double(freeHoursPerDay * 3_600) * remainingFractionToday
            : 0

        let fullDaysSeconds = fullFutureWeekdays * freeHoursPerDay * 3_600
        return max(0, todayFreeSeconds + Double(fullDaysSeconds))
    }

    private func weekdaysBetween(startDay: Date, endDay: Date, calendar: Calendar) -> Int {
        let daysBetween = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        let totalDays = daysBetween + 1
        guard totalDays > 0 else { return 0 }

        let fullWeeks = totalDays / 7
        var weekdays = fullWeeks * 5
        let remainingDays = totalDays % 7
        if remainingDays > 0 {
            let startWeekday = calendar.component(.weekday, from: startDay) // 1 = Sunday
            for offset in 0..<remainingDays {
                let weekday = ((startWeekday - 1 + offset) % 7) + 1
                if weekday >= 2 && weekday <= 6 {
                    weekdays += 1
                }
            }
        }
        return weekdays
    }

    private func isWeekday(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday >= 2 && weekday <= 6
    }
}
