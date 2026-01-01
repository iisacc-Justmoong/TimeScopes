//
//  UserDefaultsUserProfileStore.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

struct UserDefaultsUserProfileStore: UserProfileStoring {
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    init(userDefaults: UserDefaults = .standard, userDefaultsKey: String = "UserData") {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
    }

    func loadProfile() -> UserProfile? {
        let decoder = JSONDecoder()
        guard let savedData = userDefaults.data(forKey: userDefaultsKey),
              let snapshot = try? decoder.decode(UserProfileSnapshot.self, from: savedData) else {
            return nil
        }

        return UserProfile(
            name: snapshot.name,
            birthday: snapshot.birthday,
            deathDate: snapshot.deathDate,
            sex: snapshot.sex
        )
    }

    func saveProfile(_ profile: UserProfile) {
        let encoder = JSONEncoder()
        let snapshot = UserProfileSnapshot(
            name: profile.name,
            birthday: profile.birthday,
            deathDate: profile.deathDate,
            age: nil,
            deathAge: nil,
            sex: profile.sex
        )
        if let encoded = try? encoder.encode(snapshot) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }
    }
}

private struct UserProfileSnapshot: Codable {
    var name: String
    var birthday: Date
    var deathDate: Date
    var age: Int?
    var deathAge: Int?
    var sex: String
}
