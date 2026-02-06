//
//  EventDetailView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-01-25.
//

import SwiftUI

struct EventDetailView<ExtraContent: View>: View {
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
    let extraContent: () -> ExtraContent
    let showsExtraContent: Bool

    init(
        title: String,
        count: Int,
        unit: String,
        gauge: GaugeData? = nil,
        breakdown: [BreakdownItem] = []
    ) where ExtraContent == EmptyView {
        self.title = title
        self.count = count
        self.unit = unit
        self.gauge = gauge
        self.breakdown = breakdown
        self.extraContent = { EmptyView() }
        self.showsExtraContent = false
    }

    init(
        title: String,
        count: Int,
        unit: String,
        gauge: GaugeData? = nil,
        breakdown: [BreakdownItem] = [],
        @ViewBuilder extraContent: @escaping () -> ExtraContent
    ) {
        self.title = title
        self.count = count
        self.unit = unit
        self.gauge = gauge
        self.breakdown = breakdown
        self.extraContent = extraContent
        self.showsExtraContent = true
    }

    var body: some View {
        ScrollView {
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
                    let normalized = normalizeGauge(value: gauge.value, min: gauge.min, max: gauge.max)
                    Gauge(value: normalized.value, in: normalized.lower...normalized.upper) {
                        Text("\(Int(normalized.value))")
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(Color.accentColor)
                    .labelsHidden()
                }

                if showsExtraContent {
                    extraContent()
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
            }
            .padding()
        }
        .glassScreen()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var circularGaugeView: some View {
        let fallbackMax = Swift.max(1, count)
        let normalized = normalizeGauge(
            value: gauge?.value ?? count,
            min: gauge?.min ?? 0,
            max: gauge?.max ?? fallbackMax
        )
        let range = Swift.max(1, normalized.upper - normalized.lower)
        let percent = (normalized.value - normalized.lower) / range * 100

        return Gauge(value: normalized.value, in: normalized.lower...normalized.upper) {
            Text("\(percent, specifier: "%.0f")%")
                .font(.headline)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .foregroundStyle(Color.accentColor)
        .tint(Color.accentColor)
        .frame(width: 64, height: 64, alignment: .topTrailing)
    }

    private func normalizeGauge(value: Int, min: Int, max: Int) -> (value: Double, lower: Double, upper: Double) {
        let lower = Double(Swift.min(min, max))
        let rawUpper = Double(Swift.max(min, max))
        let upper = rawUpper > lower ? rawUpper : lower + 1
        let clamped = Swift.min(Swift.max(Double(value), lower), upper)
        return (value: clamped, lower: lower, upper: upper)
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
