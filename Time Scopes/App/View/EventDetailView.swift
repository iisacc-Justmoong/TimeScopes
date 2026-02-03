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
    let extraContent: AnyView?

    init(
        title: String,
        count: Int,
        unit: String,
        gauge: GaugeData? = nil,
        breakdown: [BreakdownItem] = [],
        extraContent: AnyView? = nil
    ) {
        self.title = title
        self.count = count
        self.unit = unit
        self.gauge = gauge
        self.breakdown = breakdown
        self.extraContent = extraContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(count) \(unit)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                circularGaugeView
            }

            if let gauge {
                Gauge(value: Double(gauge.value), in: Double(gauge.min)...Double(gauge.max)) {
                    Text("\(gauge.value)")
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(Color.accentColor)
                .labelsHidden()
            }

            if let extraContent {
                extraContent
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
        .glassScreen()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var circularGaugeView: some View {
        let gaugeValue = gauge?.value ?? count
        let gaugeMin = gauge?.min ?? 0
        let gaugeMax = gauge?.max ?? max(1, count)
        let range = max(1, gaugeMax - gaugeMin)
        let percent = Double(max(0, gaugeValue - gaugeMin)) / Double(range) * 100

        return Gauge(value: Double(gaugeValue), in: Double(gaugeMin)...Double(gaugeMax)) {
            Text("\(percent, specifier: "%.0f")%")
                .font(.headline)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .foregroundStyle(Color.accentColor)
        .tint(Color.accentColor)
        .frame(width: 64, height: 64, alignment: .topTrailing)
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
