//
//  RemainingCount.swift
//  Time Scopes
//
//  Created by 윤무영 on 6/24/25.
//

import Foundation
import Combine

class RemainingCount: ObservableObject {
    @Published private(set) var remaining: Int = 0

    let userData: UserData
    private let calculator: RemainingTimeCalculating
    private let dateProvider: DateProviding
    private var cancellables: Set<AnyCancellable> = []

    init(
        userData: UserData,
        calculator: RemainingTimeCalculating = RemainingTimeCalculator(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.userData = userData
        self.calculator = calculator
        self.dateProvider = dateProvider
        recalculate()
        bindUpdates()
    }

    func remainingUnit() -> RemainingTimeUnit {
        .days
    }

    func recalculate() {
        let now = dateProvider.now()
        remaining = max(calculator.remaining(unit: remainingUnit(), from: now, to: userData.deathDate), 0)
    }

    private func bindUpdates() {
        userData.$deathDate
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculate()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculate()
            }
            .store(in: &cancellables)
    }
}
