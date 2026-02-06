//
//  CalcChristmas.swift
//  Chrono
//
//  Created by 윤무영 on 11/29/24.
//

import Foundation

struct AnnualChristmasProperties {
    let name: String = "Next Christmas :"
    var count: Int = 0
    var gaugeValue: Int = 0

    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
        update()
    }

    func remainingChristmasDays() -> Int {
        let now = dateProvider.now()
        let calendar = dateProvider.calendar
        let currentYear = calendar.component(.year, from: now)

        guard let christmasDate = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 25)) else {
            return 0
        }

        let startOfToday = calendar.startOfDay(for: now)
        let startOfChristmas = calendar.startOfDay(for: christmasDate)

        if startOfToday > startOfChristmas {
            guard let nextChristmasDate = calendar.date(from: DateComponents(year: currentYear + 1, month: 12, day: 25)) else {
                return 0
            }
            let days = calendar.dateComponents([.day], from: startOfToday, to: nextChristmasDate).day ?? 0
            return days
        }

        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfChristmas).day ?? 0
        return days + 1
    }

    func daysPassedInYear() -> Int {
        let now = dateProvider.now()
        guard let startOfYear = dateProvider.calendar.date(from: DateComponents(year: dateProvider.calendar.component(.year, from: now), month: 1, day: 1)) else {
            return 0
        }
        return dateProvider.calendar.dateComponents([.day], from: startOfYear, to: now).day ?? 0
    }

    mutating func update() {
        count = remainingChristmasDays()
        gaugeValue = daysPassedInYear()
    }
}
