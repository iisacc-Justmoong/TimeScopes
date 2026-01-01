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
}
