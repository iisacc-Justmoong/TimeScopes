//
//  UntilBirth.swift
//  Chrono
//
//  Created by ymy on 2/11/25.
//

import Foundation

extension UserData {
    func daysUntilBirth() -> Int {
        let dateProvider = SystemDateProvider()
        let today = dateProvider.today()
        if birthday > today {
            return dateProvider.calendar.dateComponents([.day], from: today, to: birthday).day ?? 0
        }
        return 0
    }
}
