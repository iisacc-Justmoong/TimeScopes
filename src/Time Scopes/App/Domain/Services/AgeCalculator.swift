//
//  AgeCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

protocol AgeCalculating {
    func age(birthday: Date, now: Date) -> Int
    func deathAge(birthday: Date, deathDate: Date) -> Int
}

struct AgeCalculator: AgeCalculating {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func age(birthday: Date, now: Date) -> Int {
        dateProvider.calendar.dateComponents([.year], from: birthday, to: now).year ?? 0
    }

    func deathAge(birthday: Date, deathDate: Date) -> Int {
        dateProvider.calendar.dateComponents([.year], from: birthday, to: deathDate).year ?? 0
    }
}
