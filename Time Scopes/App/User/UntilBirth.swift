//
//  UntilBirth.swift
//  Chrono
//
//  Created by ymy on 2/11/25.
//

import Foundation

extension UserData {
    func daysUntilBirth() -> Int {
        let today = DateUtility.today()
        if birthday > today {
            return DateUtility.calendar.dateComponents([.day], from: today, to: birthday).day ?? 0
        }
        return 0
    }
}
