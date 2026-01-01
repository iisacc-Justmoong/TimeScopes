//
//  Monday.swift
//  Chrono
//
//  Created by 윤무영 on 12/13/24.
//

import Foundation

struct AnnualMondayProperties {
    let name: String = "Remining Mondays :"
    var count: Int = 0

    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
        update()
    }

    func calculateMondays(from startDate: Date, to endDate: Date) -> Int {
        var mondaysCount = 0
        var date = startDate

        while date <= endDate {
            if dateProvider.calendar.component(.weekday, from: date) == 2 {
                mondaysCount += 1
            }
            date = dateProvider.calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return mondaysCount
    }

    func remainingMondaysInYear() -> Int {
        let now = dateProvider.now()
        let currentYear = dateProvider.calendar.component(.year, from: now)

        guard let startOfYear = dateProvider.calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = dateProvider.calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
            return 0
        }

        let mondaysPassed = calculateMondays(from: startOfYear, to: now)
        let totalMondays = calculateMondays(from: startOfYear, to: endOfYear)
        return totalMondays - mondaysPassed
    }

    func totalMondaysInYear() -> Int {
        let now = dateProvider.now()
        let currentYear = dateProvider.calendar.component(.year, from: now)

        guard let startOfYear = dateProvider.calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = dateProvider.calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
            return 0
        }

        return calculateMondays(from: startOfYear, to: endOfYear)
    }

    mutating func update() {
        count = remainingMondaysInYear()
    }
}
