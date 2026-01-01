//
//  NextEventCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

struct NextBirthdayStats {
    var daysUntilNextBirthday: Int
    var daysInYear: Int
}

struct NextDecadeStats {
    var nextDecade: Int
    var yearsUntilNextDecade: Int
}

protocol NextEventCalculating {
    func nextBirthdayStats(from birthday: Date) -> NextBirthdayStats
    func nextDecadeStats(from currentAge: Int) -> NextDecadeStats
}

struct NextEventCalculator: NextEventCalculating {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func nextBirthdayStats(from birthday: Date) -> NextBirthdayStats {
        let today = dateProvider.today()
        let calendar = dateProvider.calendar
        let nextBirthday = calendar.nextDate(after: today, matching: calendar.dateComponents([.month, .day], from: birthday), matchingPolicy: .nextTimePreservingSmallerComponents) ?? today
        let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
        let daysInYear = dateProvider.daysInYear(for: today)

        return NextBirthdayStats(daysUntilNextBirthday: daysUntil, daysInYear: daysInYear)
    }

    func nextDecadeStats(from currentAge: Int) -> NextDecadeStats {
        let nextDecade = ((currentAge / 10) + 1) * 10
        let yearsUntil = nextDecade - currentAge
        return NextDecadeStats(nextDecade: nextDecade, yearsUntilNextDecade: yearsUntil)
    }
}
