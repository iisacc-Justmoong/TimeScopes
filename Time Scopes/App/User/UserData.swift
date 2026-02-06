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
    @Published var workHoursPerDay: Int = 8
    @Published var sleepHoursPerDay: Int = 8

    private let store: UserProfileStoring
    private let ageCalculator: AgeCalculating
    private let dateProvider: DateProviding
    private let widgetStore: WidgetSnapshotStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: UserProfileStoring = UserDefaultsUserProfileStore(),
        ageCalculator: AgeCalculating = AgeCalculator(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.store = store
        self.ageCalculator = ageCalculator
        self.dateProvider = dateProvider
        self.widgetStore = WidgetSnapshotStore()

        if let profile = store.loadProfile() {
            applyProfile(profile)
        }

        configureDateObservers()
        configureWidgetSync()
        updateDerivedFields()
        syncWidgetSnapshot()
    }

    func saveProfile() {
        store.saveProfile(currentProfile())
        syncWidgetSnapshot()
    }

    private func currentProfile() -> UserProfile {
        UserProfile(
            name: name,
            birthday: birthday,
            deathDate: deathDate,
            sex: sex,
            workHoursPerDay: workHoursPerDay,
            sleepHoursPerDay: sleepHoursPerDay
        )
    }

    private func applyProfile(_ profile: UserProfile) {
        name = profile.name
        birthday = profile.birthday
        deathDate = profile.deathDate
        sex = profile.sex
        workHoursPerDay = profile.workHoursPerDay
        sleepHoursPerDay = profile.sleepHoursPerDay
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
                self?.syncWidgetSnapshot()
            }
            .store(in: &cancellables)
    }

    private func configureWidgetSync() {
        let publishers: [AnyPublisher<Void, Never>] = [
            $name.map { _ in () }.eraseToAnyPublisher(),
            $birthday.map { _ in () }.eraseToAnyPublisher(),
            $deathDate.map { _ in () }.eraseToAnyPublisher(),
            $sex.map { _ in () }.eraseToAnyPublisher(),
            $workHoursPerDay.map { _ in () }.eraseToAnyPublisher(),
            $sleepHoursPerDay.map { _ in () }.eraseToAnyPublisher(),
            $age.map { _ in () }.eraseToAnyPublisher(),
            $deathAge.map { _ in () }.eraseToAnyPublisher(),
        ]

        Publishers.MergeMany(publishers)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncWidgetSnapshot()
            }
            .store(in: &cancellables)
    }

    private func syncWidgetSnapshot() {
        let current = widgetStore.loadSnapshot()
        let profile = WidgetSnapshot.Profile(
            name: name,
            age: age,
            monthsLeft: current.profile.monthsLeft,
            weeksLeft: current.profile.weeksLeft,
            daysLeft: current.profile.daysLeft
        )
        let snapshot = WidgetSnapshot(
            updatedAt: dateProvider.now(),
            profile: profile,
            elapsed: current.elapsed,
            milestones: current.milestones,
            highlights: current.highlights,
            daily: current.daily,
            pulse: current.pulse
        )
        widgetStore.saveSnapshot(snapshot)
    }
}
