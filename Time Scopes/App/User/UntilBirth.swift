//
//  UntilBirth.swift
//  Chrono
//
//  Created by ymy on 2/11/25.
//

import Foundation

extension UserData {
    func daysUntilBirth() -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        if birthday > today {
            return calendar.dateComponents([.day], from: today, to: birthday).day ?? 0
        }
        return 0
    }
}
