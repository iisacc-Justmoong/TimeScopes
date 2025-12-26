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

    override func calculateRemaining(from userData: UserData) -> Int {
        let deathDate = userData.deathDate
        let now = DateUtility.now()
        let leftComponents = DateUtility.calendar.dateComponents([.year, .month], from: now, to: deathDate)
        return (leftComponents.year ?? 0) * 12 + (leftComponents.month ?? 0)
    }
}
