//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import DeviceActivity
import SwiftUI
import UIKit

struct PulseView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var screenTimeAuth: ScreenTimeAuthorization
    @EnvironmentObject private var screenTimeMonitor: ScreenTimeMonitor
    @State private var shouldLoadReports = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    if !screenTimeAuth.isAuthorized || !screenTimeMonitor.isMonitoring || screenTimeMonitor.lastError != nil {
                        accessCard
                    }
                    TimelineView(.periodic(from: Date(), by: 300)) { timeline in
                        VStack(alignment: .leading, spacing: 20) {
                            ReportCard(title: "Weekly Summary") {
                                Text(weekRangeText(for: timeline.date))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                PulseReportHost(minHeight: 160, showReport: shouldLoadReports && screenTimeAuth.isAuthorized) {
                                    SummaryPlaceholderView()
                                } content: {
                                    DeviceActivityReport(.weeklySummary, filter: weeklySummaryFilter(for: timeline.date))
                                }
                            }

                            ReportCard(title: "Daily Summary") {
                                Text(dayRangeText(for: timeline.date))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                PulseReportHost(minHeight: 160, showReport: shouldLoadReports && screenTimeAuth.isAuthorized) {
                                    SummaryPlaceholderView()
                                } content: {
                                    DeviceActivityReport(.dailySummary, filter: dailySummaryFilter(for: timeline.date))
                                }
                            }

                            ReportCard(title: "Today's App Usage Report") {
                                PulseReportHost(minHeight: 260, showReport: shouldLoadReports && screenTimeAuth.isAuthorized) {
                                    TodayPlaceholderView()
                                } content: {
                                    DeviceActivityReport(.todayReport, filter: todayReportFilter(for: timeline.date))
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
            Task {
                await screenTimeMonitor.startMonitoringIfPossible()
            }
            if !shouldLoadReports {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    shouldLoadReports = true
                }
            }
        }
        .onChange(of: screenTimeAuth.status) { _ in
            Task {
                await screenTimeMonitor.startMonitoringIfPossible()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            screenTimeAuth.refresh()
            Task {
                await screenTimeMonitor.startMonitoringIfPossible()
            }
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

    private var accessCard: some View {
        ReportCard(title: "Screen Time Access") {
            Text("Allow Screen Time access to show usage data in Pulse.")
                .foregroundStyle(.secondary)
                .font(.callout)
            Text("Status: \(screenTimeAuth.statusLabel())")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(screenTimeMonitor.isMonitoring ? "Monitoring: Active" : "Monitoring: Inactive")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let error = screenTimeMonitor.lastError {
                Text("Monitoring error: \(error)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if screenTimeAuth.status == .notDetermined {
                Button("Allow Screen Time Access") {
                    screenTimeAuth.requestAuthorization()
                }
                .disabled(screenTimeAuth.isRequesting)
            } else if screenTimeAuth.status == .denied {
                Button("Open Settings") {
                    openSettings()
                }
            } else if screenTimeAuth.isAuthorized {
                Button("Retry Monitoring") {
                    Task {
                        await screenTimeMonitor.startMonitoringIfPossible()
                    }
                }
            }
        }
    }

    private func weeklySummaryFilter(for date: Date) -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .weekly(during: weekInterval(for: date)),
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

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
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

private struct PulseReportHost<Placeholder: View, Content: View>: View {
    let minHeight: CGFloat
    let showReport: Bool
    let placeholder: () -> Placeholder
    let content: () -> Content

    init(
        minHeight: CGFloat,
        showReport: Bool,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minHeight = minHeight
        self.showReport = showReport
        self.placeholder = placeholder
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            placeholder()
                .allowsHitTesting(false)
            if showReport {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: minHeight)
    }
}

private struct SummaryPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PlaceholderMetricRow(label: "Total Time")
            PlaceholderMetricRow(label: "Average Time")
            PlaceholderMetricRow(label: "Pickups")

            Divider().opacity(0.35)

            Text("Top Apps After Pickup")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(1...3, id: \.self) { rank in
                PlaceholderRankedRow(rank: rank)
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TodayPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PlaceholderMetricRow(label: "Total Time")
            PlaceholderMetricRow(label: "Pickups")
            PlaceholderMetricRow(label: "Notifications")
            PlaceholderMetricRow(label: "Longest Session")
            PlaceholderMetricRow(label: "First Pickup")

            Divider().opacity(0.35)

            Text("Top Apps")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(1...5, id: \.self) { rank in
                PlaceholderRankedRow(rank: rank)
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlaceholderMetricRow: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("—")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
    }
}

private struct PlaceholderRankedRow: View {
    let rank: Int

    var body: some View {
        HStack {
            Text("\(rank)")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)
            Text("—")
                .foregroundStyle(.secondary)
            Spacer()
            Text("—")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
    }
}

private extension DeviceActivityReport.Context {
    static let weeklySummary = Self("weeklySummary")
    static let dailySummary = Self("dailySummary")
    static let todayReport = Self("todayReport")
}

#Preview {
    PulseView()
        .environmentObject(ScreenTimeAuthorization())
        .environmentObject(ScreenTimeMonitor())
}
