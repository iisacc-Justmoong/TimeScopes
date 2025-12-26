//
//  LivedTime.swift
//  Chrono
//
//  Created by ymy on 2/11/25.
//

import Foundation
import Combine

class UserLivedTime: ObservableObject {
    @Published var livedMonths: Int = 0
    @Published var livedDays: Int = 0
    @Published var livedHours: Int = 0
    @Published var livedMinutes: Int = 0
    @Published var livedSeconds: Int = 0
    
    let userData: UserData
    private var timerCancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    init(model: UserData) {
        userData = model
        updateTimeLived()
        bindUserData()
        startTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    func updateTimeLived() {
        let now = DateUtility.now()
        let calendar = DateUtility.calendar
        let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: userData.birthday, to: now)
        livedMonths = components.month ?? 0
        livedDays = components.day ?? 0
        livedHours = components.hour ?? 0
        livedMinutes = components.minute ?? 0
        livedSeconds = components.second ?? 0
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
