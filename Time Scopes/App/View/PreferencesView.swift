//
//  PreferencesView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import EventKit
import FamilyControls
import SwiftUI

struct PreferencesView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var screenTimeAuth: ScreenTimeAuthorization

    @State private var calendarStatus = EKEventStore.authorizationStatus(for: .event)
    @State private var reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var isRequestingCalendar = false
    @State private var isRequestingReminders = false

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

                Section("Screen Time") {
                    PreferenceStatusRow(
                        title: "Access",
                        value: screenTimeAuth.statusLabel()
                    )
                    screenTimeActions
                }

                Section("Notes") {
                    Text("If access is denied, open Settings to enable it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Preferences")
        }
        .onAppear(perform: refreshStatuses)
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

    private func refreshStatuses() {
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        screenTimeAuth.refresh()
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
    private var screenTimeActions: some View {
        switch screenTimeAuth.status {
        case .notDetermined:
            Button("Allow Screen Time Access") {
                screenTimeAuth.requestAuthorization()
            }
            .disabled(screenTimeAuth.isRequesting)
        case .denied:
            Button("Open Settings") {
                openSettings()
            }
        case .approved:
            Text("Access granted.")
                .font(.callout)
                .foregroundStyle(.secondary)
        @unknown default:
            Text("Unknown status.")
                .font(.callout)
                .foregroundStyle(.secondary)
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
        .environmentObject(ScreenTimeAuthorization())
}
