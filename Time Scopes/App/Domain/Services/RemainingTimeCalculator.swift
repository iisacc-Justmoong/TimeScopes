//
//  RemainingTimeCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

enum RemainingTimeUnit {
    case months
    case weeks
    case days
}

protocol RemainingTimeCalculating {
    func remaining(unit: RemainingTimeUnit, from now: Date, to deathDate: Date) -> Int
}

struct RemainingTimeCalculator: RemainingTimeCalculating {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func remaining(unit: RemainingTimeUnit, from now: Date, to deathDate: Date) -> Int {
        switch unit {
        case .months:
            let components = dateProvider.calendar.dateComponents([.year, .month], from: now, to: deathDate)
            return (components.year ?? 0) * 12 + (components.month ?? 0)
        case .weeks:
            let remainingDays = dateProvider.calendar.dateComponents([.day], from: now, to: deathDate).day ?? 0
            return remainingDays / 7
        case .days:
            return dateProvider.calendar.dateComponents([.day], from: now, to: deathDate).day ?? 0
        }
    }
}
