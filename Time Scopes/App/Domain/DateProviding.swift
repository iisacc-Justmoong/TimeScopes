//
//  DateProviding.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

protocol DateProviding {
    var calendar: Calendar { get }

    func now() -> Date
    func startOfDay(for date: Date) -> Date
    func today() -> Date
    func daysInYear(for date: Date) -> Int
}

struct SystemDateProvider: DateProviding {
    var calendar: Calendar {
        Calendar.current
    }

    func now() -> Date {
        Date()
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func today() -> Date {
        startOfDay(for: now())
    }

    func daysInYear(for date: Date) -> Int {
        calendar.range(of: .day, in: .year, for: date)?.count ?? 365
    }
}
