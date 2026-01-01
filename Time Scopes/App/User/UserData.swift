//
//  UserProfile.swift
//  Chrono
//
//  Created by 윤무영 on 11/8/24.
//

import Foundation
import Combine

final class UserData: ObservableObject {
    @Published var name: String = ""
    @Published var birthday: Date = Date() {
        didSet {
            updateDerivedFields()
        }
    }
    @Published var deathDate: Date = Date() {
        didSet {
            updateDerivedFields()
        }
    }
    @Published var age: Int = 0
    @Published var deathAge: Int = 80
    @Published var sex: String = "Male"

    private let store: UserProfileStoring
    private let ageCalculator: AgeCalculating
    private let dateProvider: DateProviding
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: UserProfileStoring = UserDefaultsUserProfileStore(),
        ageCalculator: AgeCalculating = AgeCalculator(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.store = store
        self.ageCalculator = ageCalculator
        self.dateProvider = dateProvider

        if let profile = store.loadProfile() {
            applyProfile(profile)
        }

        configureDateObservers()
        updateDerivedFields()
    }

    func saveProfile() {
        store.saveProfile(currentProfile())
    }

    private func currentProfile() -> UserProfile {
        UserProfile(
            name: name,
            birthday: birthday,
            deathDate: deathDate,
            sex: sex
        )
    }

    private func applyProfile(_ profile: UserProfile) {
        name = profile.name
        birthday = profile.birthday
        deathDate = profile.deathDate
        sex = profile.sex
    }

    private func updateDerivedFields() {
        let now = dateProvider.now()
        age = ageCalculator.age(birthday: birthday, now: now)
        deathAge = ageCalculator.deathAge(birthday: birthday, deathDate: deathDate)
    }

    private func configureDateObservers() {
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDerivedFields()
            }
            .store(in: &cancellables)
    }
}
