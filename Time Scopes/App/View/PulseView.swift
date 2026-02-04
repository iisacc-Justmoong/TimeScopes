//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import DeviceActivity
import SwiftUI

struct PulseView: View {
    @StateObject private var screenTimeAuth = ScreenTimeAuthorization()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    SummaryCard(
                        title: "Weekly Summary",
                        rangeText: weekRangeText(for: Date()),
                        summary: weeklySummary
                    )
                    SummaryCard(
                        title: "Daily Summary",
                        rangeText: dayRangeText(for: Date()),
                        summary: dailySummary
                    )
                    todayReportSection
                }
                .padding()
            }
            .glassScreen()
        }
        .onAppear {
            screenTimeAuth.refresh()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pulse")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Screen Time insights from your device.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    private func dailyUsageFilter(for date: Date) -> DeviceActivityFilter {
        let calendar = Calendar.autoupdatingCurrent
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let interval = DateInterval(start: dayStart, end: dayEnd)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .all
        )
    }

    private var todayReportSection: some View {
        ReportCard(title: "Today's App Usage Report") {
            if screenTimeAuth.isAuthorized {
                TimelineView(.periodic(from: Date(), by: 300)) { timeline in
                    DeviceActivityReport(.today, filter: dailyUsageFilter(for: timeline.date))
                }
            } else {
                ReportPlaceholder(message: "Enable Screen Time access in Preferences to view today's report.")
            }
        }
    }

    private var weeklySummary: PulseSummary {
        summary()
    }

    private var dailySummary: PulseSummary {
        summary()
    }

    private func summary() -> PulseSummary {
        let placeholderMetrics = [
            PulseMetric(title: "Total Time", value: "—", isPlaceholder: true),
            PulseMetric(title: "Average Time", value: "—", isPlaceholder: true),
            PulseMetric(title: "Pickups", value: "—", isPlaceholder: true)
        ]

        let placeholderApps = [
            PulseRankedApp(rank: 1, name: "—", detail: "—", isPlaceholder: true),
            PulseRankedApp(rank: 2, name: "—", detail: "—", isPlaceholder: true),
            PulseRankedApp(rank: 3, name: "—", detail: "—", isPlaceholder: true)
        ]

        let note = screenTimeAuth.isAuthorized
            ? "Screen Time data will appear here once it is available."
            : "Enable Screen Time access in Preferences to see your summary."

        return PulseSummary(
            metrics: placeholderMetrics,
            topApps: placeholderApps,
            note: note
        )
    }

    private func weekRangeText(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return "This week"
        }
        let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return "\(interval.start.formatted(date: .abbreviated, time: .omitted)) – \(endDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private func dayRangeText(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct SummaryCard: View {
    let title: String
    let rangeText: String
    let summary: PulseSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(rangeText)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            ForEach(summary.metrics) { metric in
                MetricRow(metric: metric)
            }

            Divider()
                .opacity(0.4)

            Text("Top Apps After Pickup")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(summary.topApps) { app in
                RankedAppRow(app: app)
            }

            if let note = summary.note {
                Text(note)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .glassCard()
    }
}

private struct MetricRow: View {
    let metric: PulseMetric

    var body: some View {
        HStack {
            Text(metric.title)
            Spacer()
            Text(metric.value)
                .foregroundStyle(metric.isPlaceholder ? .secondary : .primary)
        }
        .font(.callout)
    }
}

private struct RankedAppRow: View {
    let app: PulseRankedApp

    var body: some View {
        HStack {
            Text("\(app.rank)")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)
            Text(app.name)
                .foregroundStyle(app.isPlaceholder ? .secondary : .primary)
            Spacer()
            Text(app.detail)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}

private struct ReportCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .glassCard()
    }
}

private struct ReportPlaceholder: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }
}

private extension DeviceActivityReport.Context {
    static let today = Self("today")
}

#Preview {
    PulseView()
}

private struct PulseSummary {
    let metrics: [PulseMetric]
    let topApps: [PulseRankedApp]
    let note: String?
}

private struct PulseMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let isPlaceholder: Bool
}

private struct PulseRankedApp: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let detail: String
    let isPlaceholder: Bool
}
