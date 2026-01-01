//
//  WorkingTimeCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

struct WorkingTime {
    var remainingWorkingDays: Int
    var remainingWorkingHours: Int
}

protocol WorkingTimeCalculating {
    func remainingWorkingTime(from today: Date, currentAge: Int, deathAge: Int) -> WorkingTime
}

struct WorkingTimeCalculator: WorkingTimeCalculating {
    private let dateProvider: DateProviding
    private let workingHoursPerDay: Int

    init(dateProvider: DateProviding = SystemDateProvider(), workingHoursPerDay: Int = 8) {
        self.dateProvider = dateProvider
        self.workingHoursPerDay = workingHoursPerDay
    }

    func remainingWorkingTime(from today: Date, currentAge: Int, deathAge: Int) -> WorkingTime {
        let expectedDeathDate = dateProvider.calendar.date(
            byAdding: .year,
            value: deathAge - currentAge,
            to: today
        ) ?? today

        guard expectedDeathDate >= today else {
            return WorkingTime(remainingWorkingDays: 0, remainingWorkingHours: 0)
        }

        let remainingDays = dateProvider.calendar.dateComponents([.day], from: today, to: expectedDeathDate).day ?? 0
        let remainingWeekdays = countWeekdays(from: today, daysRemaining: remainingDays)

        return WorkingTime(
            remainingWorkingDays: remainingWeekdays,
            remainingWorkingHours: remainingWeekdays * workingHoursPerDay
        )
    }

    private func countWeekdays(from startDate: Date, daysRemaining: Int) -> Int {
        var weekdaysCount = 0
        var date = startDate

        for _ in 0..<daysRemaining {
            if let nextDay = dateProvider.calendar.date(byAdding: .day, value: 1, to: date) {
                let weekday = dateProvider.calendar.component(.weekday, from: nextDay)
                if weekday != 1 && weekday != 7 {
                    weekdaysCount += 1
                }
                date = nextDay
            }
        }

        return weekdaysCount
    }
}
