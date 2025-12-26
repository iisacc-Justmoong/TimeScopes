//
//  LifeRemainingWorkingTime.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import Foundation
import Combine

class LifeRemainingWorkingTime: ObservableObject {
    @Published var remainingWorkingDays: Int = 0
    @Published var remainingWorkingHours: Int = 0
    
    let userLivedTime: UserLivedTime
    private var cancellables: Set<AnyCancellable> = []
    
    init(userLivedTime: UserLivedTime) {
        self.userLivedTime = userLivedTime
        updateRemainingWorkingTime()
        bindUpdates()
    }
    
    func updateRemainingWorkingTime() {
        let today = DateUtility.today()
        let expectedDeathDate = DateUtility.calendar.date(
                byAdding: .year,
                value: userLivedTime.userData.deathAge - userLivedTime.userData.age,
                to: today
            ) ?? today

        guard expectedDeathDate >= today else {
            DispatchQueue.main.async {
                self.remainingWorkingDays = 0
                self.remainingWorkingHours = 0
            }
            return
        }

        let remainingDays = DateUtility.calendar.dateComponents([.day], from: today, to: expectedDeathDate).day ?? 0
        let remainingWeekdays = countWeekdays(from: today, daysRemaining: remainingDays)
        let workingHoursPerDay = 8
        
        self.remainingWorkingDays = remainingWeekdays
        self.remainingWorkingHours = remainingWeekdays * workingHoursPerDay
    }
    
    private func countWeekdays(from startDate: Date, daysRemaining: Int) -> Int {
        var weekdaysCount = 0
        var date = startDate
        
        for _ in 0..<daysRemaining {
            if let nextDay = DateUtility.calendar.date(byAdding: .day, value: 1, to: date) {
                let weekday = DateUtility.calendar.component(.weekday, from: nextDay)
                if weekday != 1 && weekday != 7 {
                    weekdaysCount += 1
                }
                date = nextDay
            }
        }
        
        return weekdaysCount
    }

    private func bindUpdates() {
        userLivedTime.userData.$age
            .merge(with: userLivedTime.userData.$deathAge)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRemainingWorkingTime()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRemainingWorkingTime()
            }
            .store(in: &cancellables)
    }
}
