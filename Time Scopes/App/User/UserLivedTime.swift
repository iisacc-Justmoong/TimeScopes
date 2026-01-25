//
//  UserLivedTime.swift
//  Time Scopes
//
//  Created by ymy on 2/11/25.
//

import Foundation
import Combine

final class UserLivedTime: ObservableObject {
    @Published private(set) var livedTime: LivedTime = .zero

    let userData: UserData
    private let livedTimeCalculator: LivedTimeCalculating
    private let dateProvider: DateProviding
    private var timerCancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []

    init(
        model: UserData,
        livedTimeCalculator: LivedTimeCalculating = LivedTimeCalculator(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        userData = model
        self.livedTimeCalculator = livedTimeCalculator
        self.dateProvider = dateProvider
        updateTimeLived()
        bindUserData()
        startTimer()
    }

    deinit {
        stopTimer()
    }

    func updateTimeLived() {
        let now = dateProvider.now()
        livedTime = livedTimeCalculator.livedTime(from: userData.birthday, to: now)
    }

    func startTimer() {
        stopTimer()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeLived()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func bindUserData() {
        userData.$birthday
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateTimeLived()
            }
            .store(in: &cancellables)
    }
}
