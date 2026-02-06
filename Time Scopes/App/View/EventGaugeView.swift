//
//  AnnualEventView.swift
//  Chrono
//
//  Created by 윤무영 on 11/29/24.
//

import SwiftUI

struct EventGaugeView: View {
    
    var title: String
    var count: Int
    var gaugeValue: Int
    var min: Int
    var max: Int
    var unit: String

    private var normalizedGauge: (value: Double, lower: Double, upper: Double) {
        let lower = Double(Swift.min(min, max))
        let rawUpper = Double(Swift.max(min, max))
        let upper = rawUpper > lower ? rawUpper : lower + 1
        let clamped = Swift.min(Swift.max(Double(gaugeValue), lower), upper)
        return (value: clamped, lower: lower, upper: upper)
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.callout)
                Spacer()
                Text("\(count) \(unit)")
                    .foregroundStyle(Color.accentColor)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Gauge(value: normalizedGauge.value, in: normalizedGauge.lower...normalizedGauge.upper) {
                Text("\(gaugeValue)")
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .foregroundStyle(Color.accentColor)
            .tint(Color.accentColor)
            .labelsHidden()
            .font(.headline)
        }
    }
}
