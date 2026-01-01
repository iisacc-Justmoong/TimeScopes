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
    private let workingTimeCalculator: WorkingTimeCalculating
    private let dateProvider: DateProviding
    private var cancellables: Set<AnyCancellable> = []

    init(
        userLivedTime: UserLivedTime,
        workingTimeCalculator: WorkingTimeCalculating = WorkingTimeCalculator(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.userLivedTime = userLivedTime
        self.workingTimeCalculator = workingTimeCalculator
        self.dateProvider = dateProvider
        updateRemainingWorkingTime()
        bindUpdates()
    }

    func updateRemainingWorkingTime() {
        let today = dateProvider.today()
        let workingTime = workingTimeCalculator.remainingWorkingTime(
            from: today,
            currentAge: userLivedTime.userData.age,
            deathAge: userLivedTime.userData.deathAge
        )

        remainingWorkingDays = workingTime.remainingWorkingDays
        remainingWorkingHours = workingTime.remainingWorkingHours
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
