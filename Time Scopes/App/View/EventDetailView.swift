//
//  EventDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-01-25.
//

import SwiftUI

struct EventDetailView: View {
    struct GaugeData {
        let value: Int
        let min: Int
        let max: Int
    }

    struct BreakdownItem: Identifiable {
        let id = UUID()
        let label: String
        let value: Int
        let unit: String
    }

    let title: String
    let count: Int
    let unit: String
    let gauge: GaugeData?
    let breakdown: [BreakdownItem]

    init(title: String, count: Int, unit: String, gauge: GaugeData? = nil, breakdown: [BreakdownItem] = []) {
        self.title = title
        self.count = count
        self.unit = unit
        self.gauge = gauge
        self.breakdown = breakdown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(count) \(unit)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }

            if let gauge {
                Gauge(value: Double(gauge.value), in: Double(gauge.min)...Double(gauge.max)) {
                    Text("\(gauge.value)")
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(Color.accentColor)
                .labelsHidden()
            }

            if !breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Breakdown")
                        .font(.headline)
                    ForEach(breakdown) { item in
                        HStack {
                            Text(item.label)
                                .font(.callout)
                            Spacer()
                            Text("\(item.value) \(item.unit)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            title: "Sample Event",
            count: 42,
            unit: "days",
            gauge: EventDetailView.GaugeData(value: 42, min: 0, max: 100)
        )
    }
}
