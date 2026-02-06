//
//  LocationPermissionManager.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import CoreLocation
import Foundation

@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        if #available(iOS 14.0, *) {
            self.authorizationStatus = manager.authorizationStatus
        } else {
            self.authorizationStatus = CLLocationManager.authorizationStatus()
        }
        super.init()
        manager.delegate = self
    }

    func requestAccessIfNeeded() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return
        }
        requestLocationIfPossible()
    }

    func refreshStatus() {
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        requestLocationIfPossible()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }

    private func requestLocationIfPossible() {
        guard isAuthorized(authorizationStatus) else { return }
        manager.requestLocation()
    }

    private func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return true
        default:
            return false
        }
    }
}
