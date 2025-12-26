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
    private var cancellables: Set<AnyCancellable> = []

    init(userData: UserData) {
        self.userData = userData
        recalculate()
        bindUpdates()
    }

    func calculateRemaining(from userData: UserData) -> Int {
        0
    }

    func recalculate() {
        remaining = max(calculateRemaining(from: userData), 0)
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
