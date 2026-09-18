//
//  HomeFormatting.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation

enum HomeFormatting {
    static func formatHMS(_ totalSeconds: Int) -> String {
        let clamped = max(0, totalSeconds)
        let hours = clamped / 3_600
        let minutes = (clamped % 3_600) / 60
        let seconds = clamped % 60
        return "\(hours)h \(minutes)m \(seconds)s"
    }

    static func formatMS(_ totalSeconds: Int) -> String {
        let clamped = max(0, totalSeconds)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return "\(minutes)m \(seconds)s"
    }

    static func percentText(value: Int, total: Int) -> String {
        guard total > 0 else { return "0%" }
        let percent = (Double(value) / Double(total)) * 100
        return String(format: "%.0f%%", percent)
    }
}
