//
//  ScreenTimeAuthorization.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import FamilyControls
import Foundation

@MainActor
final class ScreenTimeAuthorization: ObservableObject {
    @Published private(set) var status: AuthorizationStatus
    @Published private(set) var isRequesting: Bool = false

    init() {
        self.status = AuthorizationCenter.shared.authorizationStatus
    }

    var isAuthorized: Bool {
        status == .approved
    }

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() {
        guard !isRequesting else { return }
        isRequesting = true
        Task {
            defer {
                isRequesting = false
                refresh()
            }
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                refresh()
            }
        }
    }

    func statusLabel() -> String {
        switch status {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
}
