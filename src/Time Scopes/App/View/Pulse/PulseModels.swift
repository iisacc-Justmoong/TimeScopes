//
//  PulseModels.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation

struct PulseDayIntensity: Identifiable {
    let id = UUID()
    let day: String
    let intensity: Double
}

struct PulseDayLoad: Identifiable {
    let id = UUID()
    let day: String
    let loadMinutes: Double
    let intensity: Double
    let eventMinutes: Double
    let reminderMinutes: Double
    let eventCount: Int
    let reminderCount: Int
}

struct PulseDayLoadSeed {
    let day: String
    let eventMinutes: Double
    let reminderMinutes: Double
    let eventCount: Int
    let reminderCount: Int
    let loadMinutes: Double
}

struct FocusSegment {
    let label: String
    let startHour: Int
    let endHour: Int
}

struct PulseWeeklySummary {
    let peakDayText: String
    let lowDayText: String
    let eventCountText: String
    let reminderCountText: String
    let eventTimeText: String
    let totalLoadText: String
    let averageLoadText: String
    let averageRemindersText: String
    let distributionText: String
    let freeTimeText: String
}

struct PulseWeeklyEvent: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let duration: TimeInterval
}

struct PulsePrescription: Identifiable {
    let id = UUID()
    let focus: String
    let title: String
    let detail: String
    let impact: String
}
