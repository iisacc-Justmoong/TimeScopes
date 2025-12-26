//
//  ElapsedDate.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import Foundation

struct ElapsedDateInThisYear {
    
    var daysElapsedThisWeek: Int {
        Self.daysElapsedThisWeek()
    }
    var daysElapsedThisMonth: Int {
        Self.daysElapsedThisMonth()
    }
    var daysElapsedThisYear: Int {
        Self.daysElapsedThisYear()
    }
    
    
    static func daysElapsedThisWeek() -> Int {
       
        let today = DateUtility.today()
        let startOfWeek = DateUtility.calendar.date(from: DateUtility.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        return DateUtility.calendar.dateComponents([.day], from: startOfWeek, to: today).day ?? 0
    }
    
    static func daysElapsedThisMonth() -> Int {
        
        let today = DateUtility.today()
        let startOfMonth = DateUtility.calendar.date(from: DateUtility.calendar.dateComponents([.year, .month], from: today))!

        return DateUtility.calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0
    }
    
    static func daysElapsedThisYear() -> Int {
     
        let today = DateUtility.today()
        let startOfYear = DateUtility.calendar.date(from: DateUtility.calendar.dateComponents([.year], from: today))!

        return DateUtility.calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0
    }
}
