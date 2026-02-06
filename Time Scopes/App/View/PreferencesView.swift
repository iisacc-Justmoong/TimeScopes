//
//  PreferencesView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import CoreLocation
import EventKit
import SwiftUI

struct PreferencesView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var userData: UserData
    @EnvironmentObject private var locationPermission: LocationPermissionManager

    @State private var calendarStatus = EKEventStore.authorizationStatus(for: .event)
    @State private var reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var isRequestingCalendar = false
    @State private var isRequestingReminders = false
    @State private var isRequestingLocation = false

    private let store = EKEventStore()

    var body: some View {
        NavigationStack {
            Form {
                Section("Calendar") {
                    PreferenceStatusRow(
                        title: "Access",
                        value: statusLabel(for: calendarStatus)
                    )
                    preferenceActions(
                        status: calendarStatus,
                        allowTitle: "Allow Calendar Access",
                        isRequesting: isRequestingCalendar,
                        allowAction: requestCalendarAccess
                    )
                }

                Section("Reminders") {
                    PreferenceStatusRow(
                        title: "Access",
                        value: statusLabel(for: reminderStatus)
                    )
                    preferenceActions(
                        status: reminderStatus,
                        allowTitle: "Allow Reminders Access",
                        isRequesting: isRequestingReminders,
                        allowAction: requestRemindersAccess
                    )
                }

                Section("Location") {
                    PreferenceStatusRow(
                        title: "Access",
                        value: statusLabel(for: locationPermission.authorizationStatus)
                    )
                    locationActions(
                        status: locationPermission.authorizationStatus,
                        isRequesting: isRequestingLocation
                    )
                }

                Section("Daily Schedule") {
                    Stepper(value: $userData.workHoursPerDay, in: 0...24) {
                        Text("Work: \(userData.workHoursPerDay) hours/day")
                    }
                    Stepper(value: $userData.sleepHoursPerDay, in: 0...24) {
                        Text("Sleep: \(userData.sleepHoursPerDay) hours/day")
                    }
                    if userData.workHoursPerDay + userData.sleepHoursPerDay > 24 {
                        Text("Work + sleep exceeds 24 hours. Free time is clamped to 0.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Preferences")
        }
        .onAppear(perform: refreshStatuses)
        .onChange(of: locationPermission.authorizationStatus) { _ in
            locationPermission.refreshStatus()
        }
        .onChange(of: userData.workHoursPerDay) { _ in
            userData.saveProfile()
        }
        .onChange(of: userData.sleepHoursPerDay) { _ in
            userData.saveProfile()
        }
    }

    @ViewBuilder
    private func preferenceActions(
        status: EKAuthorizationStatus,
        allowTitle: String,
        isRequesting: Bool,
        allowAction: @escaping () -> Void
    ) -> some View {
        switch status {
        case .notDetermined:
            Button(allowTitle) {
                allowAction()
            }
            .disabled(isRequesting)
        case .denied, .restricted:
            Button("Open Settings") {
                openSettings()
            }
        case .authorized, .fullAccess:
            Text("Access granted.")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .writeOnly:
            Text("Write-only access granted.")
                .font(.callout)
                .foregroundStyle(.secondary)
        @unknown default:
            Text("Unknown status.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func statusLabel(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Allowed"
        case .fullAccess:
            return "Allowed"
        case .writeOnly:
            return "Write only"
        @unknown default:
            return "Unknown"
        }
    }

    private func statusLabel(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When in Use"
        case .authorized:
            return "Allowed"
        @unknown default:
            return "Unknown"
        }
    }

    private func refreshStatuses() {
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        locationPermission.refreshStatus()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func requestCalendarAccess() {
        isRequestingCalendar = true
        Task {
            defer {
                isRequestingCalendar = false
                refreshStatuses()
            }
            if #available(iOS 17.0, *) {
                _ = try? await store.requestFullAccessToEvents()
            } else {
                _ = await withCheckedContinuation { continuation in
                    store.requestAccess(to: .event) { _, _ in
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    private func requestRemindersAccess() {
        isRequestingReminders = true
        Task {
            defer {
                isRequestingReminders = false
                refreshStatuses()
            }
            if #available(iOS 17.0, *) {
                _ = try? await store.requestFullAccessToReminders()
            } else {
                _ = await withCheckedContinuation { continuation in
                    store.requestAccess(to: .reminder) { _, _ in
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func locationActions(
        status: CLAuthorizationStatus,
        isRequesting: Bool
    ) -> some View {
        switch status {
        case .notDetermined:
            Button("Allow Location Access") {
                requestLocationAccess()
            }
            .disabled(isRequesting)
        case .denied, .restricted:
            Button("Open Settings") {
                openSettings()
            }
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            Text("Access granted.")
                .font(.callout)
                .foregroundStyle(.secondary)
        @unknown default:
            Text("Unknown status.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func requestLocationAccess() {
        isRequestingLocation = true
        locationPermission.requestAccessIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isRequestingLocation = false
            locationPermission.refreshStatus()
        }
    }
}

private struct PreferenceStatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(UserData())
}
