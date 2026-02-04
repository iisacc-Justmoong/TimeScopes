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
                    TimelineView(.periodic(from: Date(), by: 300)) { timeline in
                        VStack(alignment: .leading, spacing: 20) {
                            ReportCard(title: "Weekly Summary") {
                                Text(weekRangeText(for: timeline.date))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                if screenTimeAuth.isAuthorized {
                                    DeviceActivityReport(.weeklySummary, filter: weeklySummaryFilter(for: timeline.date))
                                } else {
                                    ReportPlaceholder(message: "Enable Screen Time access in Preferences to view weekly summary.")
                                }
                            }

                            ReportCard(title: "Daily Summary") {
                                Text(dayRangeText(for: timeline.date))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                if screenTimeAuth.isAuthorized {
                                    DeviceActivityReport(.dailySummary, filter: dailySummaryFilter(for: timeline.date))
                                } else {
                                    ReportPlaceholder(message: "Enable Screen Time access in Preferences to view daily summary.")
                                }
                            }

                            ReportCard(title: "Today's App Usage Report") {
                                if screenTimeAuth.isAuthorized {
                                    DeviceActivityReport(.todayReport, filter: todayReportFilter(for: timeline.date))
                                } else {
                                    ReportPlaceholder(message: "Enable Screen Time access in Preferences to view today's report.")
                                }
                            }
                        }
                    }
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

    private func weeklySummaryFilter(for date: Date) -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(during: weekInterval(for: date)),
            users: .all,
            devices: .all
        )
    }

    private func dailySummaryFilter(for date: Date) -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(during: dayInterval(for: date)),
            users: .all,
            devices: .all
        )
    }

    private func todayReportFilter(for date: Date) -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(during: dayInterval(for: date)),
            users: .all,
            devices: .all
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

    private func weekInterval(for date: Date) -> DateInterval {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, end: date)
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
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
    static let weeklySummary = Self("weeklySummary")
    static let dailySummary = Self("dailySummary")
    static let todayReport = Self("todayReport")
}

#Preview {
    PulseView()
}
