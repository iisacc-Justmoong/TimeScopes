//
//  UserProfileStore.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

protocol UserProfileStoring {
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile)
    func loadProfileAsync() async -> UserProfile?
    func saveProfileAsync(_ profile: UserProfile) async
}

extension UserProfileStoring {
    func loadProfileAsync() async -> UserProfile? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: loadProfile())
            }
        }
    }

    func saveProfileAsync(_ profile: UserProfile) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                saveProfile(profile)
                continuation.resume()
            }
        }
    }
}
