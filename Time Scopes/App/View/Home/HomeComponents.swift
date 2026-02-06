//
//  HomeComponents.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct DailyEventGaugeRow: View {
    let title: String
    let valueText: String
    let percentText: String
    let gaugeValue: Double
    let gaugeMax: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.callout)
                Spacer()
                Text(valueText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                Text(percentText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Gauge(value: gaugeValue, in: 0...max(1, gaugeMax)) {
                Text(percentText)
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .foregroundStyle(Color.accentColor)
            .tint(Color.accentColor)
            .labelsHidden()
        }
    }
}

struct WeekdayDetailRow: View {
    let title: String
    let value: Int
    let unit: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer()
            Text("\(value) \(unit)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
        }
    }
}
