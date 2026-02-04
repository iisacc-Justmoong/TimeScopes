//
//  ScreenTimeMonitor.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import DeviceActivity
import FamilyControls
import Foundation

@MainActor
final class ScreenTimeMonitor: ObservableObject {
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var lastError: String? = nil

    private let center = DeviceActivityCenter()

    func refresh() {
        isMonitoring = center.activities.contains(.pulseDaily)
    }

    func startMonitoringIfPossible() async {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            lastError = nil
            refresh()
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.pulseDaily, during: schedule)
            lastError = nil
        } catch {
            // If already monitoring, ignore the error and refresh status.
            lastError = error.localizedDescription
        }
        refresh()
    }
}

extension DeviceActivityName {
    static let pulseDaily = Self("pulseDaily")
}
