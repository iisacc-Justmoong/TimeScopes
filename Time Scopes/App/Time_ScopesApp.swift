//
//  Time_ScopesApp.swift
//  Time Scopes
//
//  Created by 윤무영 on 6/24/25.
//

import SwiftUI
import UIKit

@main
struct TimeScopeApp: App {
    @StateObject var userData: UserData
    @StateObject var userLivedTime: UserLivedTime
    @StateObject var monthCount: MonthCount
    @StateObject var weekCount: WeekCount
    @StateObject var dayCount: DayCount
    @StateObject private var screenTimeAuth = ScreenTimeAuthorization()
    @StateObject private var screenTimeMonitor = ScreenTimeMonitor()

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
                PulseView()
                    .tabItem {
                        Label("Pulse", systemImage: "waveform")
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
            .environmentObject(screenTimeAuth)
            .environmentObject(screenTimeMonitor)
            .task {
                screenTimeAuth.refresh()
                await screenTimeMonitor.startMonitoringIfPossible()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                screenTimeAuth.refresh()
                Task {
                    await screenTimeMonitor.startMonitoringIfPossible()
                }
            }
        }
    }
}
