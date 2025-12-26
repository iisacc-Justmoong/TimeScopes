//
//  DateUtility.swift
//  Chrono
//
//  Created by ymy on 1/17/25.
//

import Foundation

enum DateUtility {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static var calendar: Calendar {
        Calendar.current
    }

    static func now() -> Date {
        Date()
    }

    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func today() -> Date {
        startOfDay(for: now())
    }

    static func daysInYear(for date: Date) -> Int {
        calendar.range(of: .day, in: .year, for: date)?.count ?? 365
    }
}
