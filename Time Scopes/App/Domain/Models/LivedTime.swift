//
//  LivedTime.swift
//  Time Scopes
//
//  Created by OpenAI on 2025-02-14.
//

import Foundation

struct LivedTime {
    let months: Int
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    static let zero = LivedTime(months: 0, days: 0, hours: 0, minutes: 0, seconds: 0)
}
