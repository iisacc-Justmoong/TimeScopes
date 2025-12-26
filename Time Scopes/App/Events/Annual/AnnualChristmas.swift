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

    init() {
        self.update()
    }
    
    static func remainingChristmasDays() -> Int {

        let now = DateUtility.now()
        let currentYear = DateUtility.calendar.component(.year, from: now)
        
        guard let christmasDate = DateUtility.calendar.date(from: DateComponents(year: currentYear, month: 12, day: 25)) else {
            return 0
        }
        
        if now > christmasDate {
            guard let nextChristmasDate = DateUtility.calendar.date(from: DateComponents(year: currentYear + 1, month: 12, day: 25)) else {
                return 0
            }
            let days = DateUtility.calendar.dateComponents([.day], from: now, to: nextChristmasDate).day ?? 0
            return days
        }
        
        let days = DateUtility.calendar.dateComponents([.day], from: now, to: christmasDate).day ?? 0
        return days + 1
    }
    static func daysPassedInYear() -> Int {
        
        let now = DateUtility.now()
        guard let startOfYear = DateUtility.calendar.date(from: DateComponents(year: DateUtility.calendar.component(.year, from: now), month: 1, day: 1)) else {
            return 0
        }
        return DateUtility.calendar.dateComponents([.day], from: startOfYear, to: now).day ?? 0
    }
    
    mutating func update() {
        count = AnnualChristmasProperties.remainingChristmasDays()
        gaugeValue = AnnualChristmasProperties.daysPassedInYear()
    }
}
