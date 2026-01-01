//
//  ElapsedDate.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import Foundation

struct ElapsedDateInThisYear {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    var daysElapsedThisWeek: Int {
        daysElapsedThisWeek()
    }
    var daysElapsedThisMonth: Int {
        daysElapsedThisMonth()
    }
    var daysElapsedThisYear: Int {
        daysElapsedThisYear()
    }

    func daysElapsedThisWeek() -> Int {
        let today = dateProvider.today()
        let startOfWeek = dateProvider.calendar.date(from: dateProvider.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today

        return dateProvider.calendar.dateComponents([.day], from: startOfWeek, to: today).day ?? 0
    }

    func daysElapsedThisMonth() -> Int {
        let today = dateProvider.today()
        let startOfMonth = dateProvider.calendar.date(from: dateProvider.calendar.dateComponents([.year, .month], from: today)) ?? today

        return dateProvider.calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0
    }

    func daysElapsedThisYear() -> Int {
        let today = dateProvider.today()
        let startOfYear = dateProvider.calendar.date(from: dateProvider.calendar.dateComponents([.year], from: today)) ?? today

        return dateProvider.calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0
    }
}
