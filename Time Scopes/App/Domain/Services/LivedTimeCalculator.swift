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
    init() {}

    func livedTime(from birthday: Date, to now: Date) -> LivedTime {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(birthday)))
        let totalMinutes = elapsedSeconds / 60
        let totalHours = elapsedSeconds / 3600
        let totalDays = elapsedSeconds / 86_400
        let totalMonths = totalDays / 30

        return LivedTime(
            months: totalMonths,
            days: totalDays,
            hours: totalHours,
            minutes: totalMinutes,
            seconds: elapsedSeconds
        )
    }
}
