//
//  SecondTicker.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import Combine
import Foundation

@MainActor
final class SecondTicker: ObservableObject {
    @Published private(set) var now: Date

    private var cancellable: AnyCancellable?

    init() {
        now = Date()
        cancellable = Timer.publish(every: 1.0, tolerance: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
            }
    }

    deinit {
        cancellable?.cancel()
    }
}
