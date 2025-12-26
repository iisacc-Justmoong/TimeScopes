//
//  DayCount.swift
//  Chrono
//
//  Created by ymy on 1/21/25.
//

import Foundation

final class DayCount: RemainingCount {
    var leftDays: Int {
        remaining
    }

    init(viewModel: UserData) {
        super.init(userData: viewModel)
    }

    override func calculateRemaining(from userData: UserData) -> Int {
        let deathDate = userData.deathDate
        return DateUtility.calendar.dateComponents([.day], from: DateUtility.now(), to: deathDate).day ?? 0
    }
}
