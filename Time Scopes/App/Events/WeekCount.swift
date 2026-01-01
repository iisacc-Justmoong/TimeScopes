//
//  WeekCount.swift
//  Chrono
//
//  Created by ymy on 1/21/25.
//

import Foundation

final class WeekCount: RemainingCount {
    var leftWeeks: Int {
        remaining
    }

    init(viewModel: UserData) {
        super.init(userData: viewModel)
    }

    override func remainingUnit() -> RemainingTimeUnit {
        .weeks
    }
}
