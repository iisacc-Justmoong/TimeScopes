//
//  Time_ScopesApp.swift
//  Time Scopes
//
//  Created by 윤무영 on 6/24/25.
//

import SwiftUI

private enum AppTab: Hashable {
    case home
    case calendar
    case pulse
    case preferences
}

@main
struct TimeScopeApp: App {
    @StateObject var userData: UserData
    @StateObject var userLivedTime: UserLivedTime
    @StateObject var monthCount: MonthCount
    @StateObject var weekCount: WeekCount
    @StateObject var dayCount: DayCount
    @StateObject var locationPermission: LocationPermissionManager
    @StateObject var deepLinkCenter = AppDeepLinkCenter()

    init() {
        let sharedUserData = UserData()
        _userData = StateObject(wrappedValue: sharedUserData)
        _userLivedTime = StateObject(wrappedValue: UserLivedTime(model: sharedUserData))
        _monthCount = StateObject(wrappedValue: MonthCount(viewModel: sharedUserData))
        _weekCount = StateObject(wrappedValue: WeekCount(viewModel: sharedUserData))
        _dayCount = StateObject(wrappedValue: DayCount(viewModel: sharedUserData))
        _locationPermission = StateObject(wrappedValue: LocationPermissionManager())
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(userLivedTime: userLivedTime)
            .environmentObject(userData)
            .environmentObject(userLivedTime)
            .environmentObject(monthCount)
            .environmentObject(weekCount)
            .environmentObject(dayCount)
            .environmentObject(locationPermission)
            .environmentObject(deepLinkCenter)
            .task {
                locationPermission.requestAccessIfNeeded()
            }
        }
    }
}

private struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var deepLinkCenter: AppDeepLinkCenter
    @ObservedObject var userLivedTime: UserLivedTime
    @State private var selectedTab: AppTab = .home
    @State private var routeRetryTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(lifeRemainingWorkingTime: LifeRemainingWorkingTime(userLivedTime: userLivedTime))
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(AppTab.calendar)
            PulseView()
                .tabItem {
                    Label("Pulse", systemImage: "waveform")
                }
                .tag(AppTab.pulse)
            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
                .tag(AppTab.preferences)
        }
        .onAppear {
            routeWidgetActionIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                routeWidgetActionIfNeeded()
            } else {
                cancelRouteRetry()
            }
        }
        .onDisappear {
            cancelRouteRetry()
        }
        .onOpenURL { url in
            handleDeepLinkURL(url)
        }
    }

    private func routeWidgetActionIfNeeded() {
        if routeToPulseIfRequested() {
            return
        }
        cancelRouteRetry()
        routeRetryTask = Task { @MainActor in
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                if routeToPulseIfRequested() {
                    cancelRouteRetry()
                    return
                }
            }
            cancelRouteRetry()
        }
    }

    @discardableResult
    private func routeToPulseIfRequested() -> Bool {
        guard PulseJournalWidgetAction.hasPendingOpenComposerRequest else {
            return false
        }
        selectedTab = .pulse
        NotificationCenter.default.post(name: .pulseJournalComposeRequested, object: nil)
        return true
    }

    private func handleDeepLinkURL(_ url: URL) {
        guard let route = AppDeepLink(url: url) else { return }
        selectedTab = tab(for: route.tab)
        deepLinkCenter.open(route)
    }

    private func tab(for deepLinkTab: AppDeepLinkTab) -> AppTab {
        switch deepLinkTab {
        case .home:
            return .home
        case .calendar:
            return .calendar
        case .pulse:
            return .pulse
        case .preferences:
            return .preferences
        }
    }

    private func cancelRouteRetry() {
        routeRetryTask?.cancel()
        routeRetryTask = nil
    }
}
