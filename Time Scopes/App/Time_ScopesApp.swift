//
//  Time_ScopesApp.swift
//  Time Scopes
//
//  Created by 윤무영 on 6/24/25.
//

import SwiftUI

@main
struct TimeScopeApp: App {
    @StateObject var userData: UserData
    @StateObject var userLivedTime: UserLivedTime
    @StateObject var monthCount: MonthCount
    @StateObject var weekCount: WeekCount
    @StateObject var dayCount: DayCount

    init() {
        let sharedUserData = UserData()
        _userData = StateObject(wrappedValue: sharedUserData)
        _userLivedTime = StateObject(wrappedValue: UserLivedTime(model: sharedUserData))
        _monthCount = StateObject(wrappedValue: MonthCount(viewModel: sharedUserData))
        _weekCount = StateObject(wrappedValue: WeekCount(viewModel: sharedUserData))
        _dayCount = StateObject(wrappedValue: DayCount(viewModel: sharedUserData))
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView(lifeRemainingWorkingTime: LifeRemainingWorkingTime(userLivedTime: userLivedTime))
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                PreferencesView()
                    .tabItem {
                        Label("Preferences", systemImage: "gearshape")
                    }
            }
            .environmentObject(userData)
            .environmentObject(userLivedTime)
            .environmentObject(monthCount)
            .environmentObject(weekCount)
            .environmentObject(dayCount)
        }
    }
}
