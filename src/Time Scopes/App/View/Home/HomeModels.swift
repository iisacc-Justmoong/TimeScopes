//
//  HomeModels.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation

struct HomeGaugeData {
    let title: String
    let valueText: String
    let percentText: String
    let value: Double
    let max: Double
}

struct HomeDailySummary {
    let nextHour: HomeGaugeData
    let sun: HomeGaugeData
    let timeLeft: HomeGaugeData
    let freeTime: HomeGaugeData
    let allocatedTime: HomeGaugeData
}
