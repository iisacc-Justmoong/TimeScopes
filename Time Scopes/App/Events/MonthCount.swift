//
//  AnnualEvent.swift
//  Chrono
//
//  Created by 윤무영 on 11/29/24.
//
import Foundation

final class MonthCount: RemainingCount {
    var leftMonths: Int {
        remaining
    }

    init(viewModel: UserData) {
        super.init(userData: viewModel)
    }

    override func remainingUnit() -> RemainingTimeUnit {
        .months
    }
}
