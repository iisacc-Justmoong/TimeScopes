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
            Gauge(value: Double(gaugeValue), in: Double(min)...Double(max)) {
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
