//
//  LifeRemainingWorkingTime.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import Foundation
import Combine

final class LifeRemainingWorkingTime: ObservableObject {
    @Published var remainingWorkingDays: Int = 0
    @Published var remainingWorkingHours: Int = 0

    let userLivedTime: UserLivedTime
    private let dateProvider: DateProviding
    private var cancellables: Set<AnyCancellable> = []

    init(
        userLivedTime: UserLivedTime,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.userLivedTime = userLivedTime
        self.dateProvider = dateProvider
        updateRemainingWorkingTime()
        bindUpdates()
    }

    func updateRemainingWorkingTime() {
        let startDate = dateProvider.calendar.startOfDay(for: userLivedTime.userData.birthday)
        let endDate = dateProvider.calendar.startOfDay(for: userLivedTime.userData.deathDate)
        guard endDate >= startDate else {
            remainingWorkingDays = 0
            remainingWorkingHours = 0
            return
        }

        let weekdays = countWeekdays(from: startDate, to: endDate)
        let workHoursPerDay = max(0, min(userLivedTime.userData.workHoursPerDay, 24))
        remainingWorkingDays = weekdays
        remainingWorkingHours = weekdays * workHoursPerDay
    }

    private func bindUpdates() {
        let birthdayChanges = userLivedTime.userData.$birthday.map { _ in () }
        let deathChanges = userLivedTime.userData.$deathDate.map { _ in () }
        let workHoursChanges = userLivedTime.userData.$workHoursPerDay.map { _ in () }

        Publishers.Merge3(birthdayChanges, deathChanges, workHoursChanges)
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

    private func countWeekdays(from startDate: Date, to endDate: Date) -> Int {
        var count = 0
        var date = startDate

        while date <= endDate {
            let weekday = dateProvider.calendar.component(.weekday, from: date)
            if weekday != 1 && weekday != 7 {
                count += 1
            }
            guard let next = dateProvider.calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = next
        }

        return count
    }
}
