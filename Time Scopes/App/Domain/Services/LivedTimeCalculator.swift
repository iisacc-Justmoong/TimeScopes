//
//  LivedTimeCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

protocol LivedTimeCalculating {
    func livedTime(from birthday: Date, to now: Date) -> LivedTime
}

struct LivedTimeCalculator: LivedTimeCalculating {
    private let dateProvider: DateProviding

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func livedTime(from birthday: Date, to now: Date) -> LivedTime {
        let components = dateProvider.calendar.dateComponents([.month, .day, .hour, .minute, .second], from: birthday, to: now)
        return LivedTime(
            months: components.month ?? 0,
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0,
            seconds: components.second ?? 0
        )
    }
}
