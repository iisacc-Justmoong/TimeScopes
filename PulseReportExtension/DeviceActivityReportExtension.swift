//
//  DeviceActivityReportExtension.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import DeviceActivity
import ManagedSettings
import SwiftUI

@main
struct PulseReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        WeeklySummaryScene()
        DailySummaryScene()
        TodayReportScene()
    }
}

private struct WeeklySummaryScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .weeklySummary

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> PulseSummaryConfiguration {
        let aggregate = await PulseActivityAggregate.aggregate(from: data)
        let average = aggregate.averageDuration(divisor: max(1, aggregate.segmentCount))
        return PulseSummaryConfiguration(
            totalDuration: aggregate.totalDuration,
            averageDuration: average,
            totalPickups: aggregate.totalPickups,
            topApps: aggregate.topAppsSortedByPickups(limit: 3)
        )
    }

    let content: (PulseSummaryConfiguration) -> PulseSummaryView = { configuration in
        PulseSummaryView(configuration: configuration)
    }
}

private struct DailySummaryScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .dailySummary

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> PulseSummaryConfiguration {
        let aggregate = await PulseActivityAggregate.aggregate(from: data)
        let average = aggregate.averageDuration(divisor: max(1, aggregate.segmentCount))
        return PulseSummaryConfiguration(
            totalDuration: aggregate.totalDuration,
            averageDuration: average,
            totalPickups: aggregate.totalPickups,
            topApps: aggregate.topAppsSortedByPickups(limit: 3)
        )
    }

    let content: (PulseSummaryConfiguration) -> PulseSummaryView = { configuration in
        PulseSummaryView(configuration: configuration)
    }
}

private struct TodayReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .todayReport

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> PulseTodayConfiguration {
        let aggregate = await PulseActivityAggregate.aggregate(from: data)
        return PulseTodayConfiguration(
            totalDuration: aggregate.totalDuration,
            totalPickups: aggregate.totalPickups,
            totalNotifications: aggregate.totalNotifications,
            longestActivityDuration: aggregate.longestActivityDuration,
            firstPickup: aggregate.firstPickup,
            topApps: aggregate.topAppsSortedByDuration(limit: 8),
            topCategories: aggregate.topCategories(limit: 5),
            topWebsites: aggregate.topWebsites(limit: 5)
        )
    }

    let content: (PulseTodayConfiguration) -> PulseTodayView = { configuration in
        PulseTodayView(configuration: configuration)
    }
}

private struct PulseSummaryView: View {
    let configuration: PulseSummaryConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MetricRow(label: "Total Time", value: PulseFormatters.formatDuration(configuration.totalDuration))
            MetricRow(label: "Average Time", value: PulseFormatters.formatDuration(configuration.averageDuration))
            MetricRow(label: "Pickups", value: "\(configuration.totalPickups)")

            Divider().opacity(0.35)

            Text("Top Apps After Pickup")
                .font(.subheadline)
                .fontWeight(.semibold)

            if configuration.totalDuration == 0 && configuration.totalPickups == 0 && configuration.topApps.isEmpty {
                Text("No activity data yet. Usage appears after monitoring begins.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            if configuration.topApps.isEmpty {
                Text("No activity recorded yet.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(Array(configuration.topApps.enumerated()), id: \.offset) { index, app in
                    RankedAppRow(
                        rank: index + 1,
                        name: app.name,
                        detail: "\(app.pickups) pickups · \(PulseFormatters.formatDuration(app.duration))"
                    )
                }
            }
        }
        .font(.callout)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PulseTodayView: View {
    let configuration: PulseTodayConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetricRow(label: "Total Time", value: PulseFormatters.formatDuration(configuration.totalDuration))
            MetricRow(label: "Pickups", value: "\(configuration.totalPickups)")
            MetricRow(label: "Notifications", value: "\(configuration.totalNotifications)")
            if configuration.longestActivityDuration > 0 {
                MetricRow(label: "Longest Session", value: PulseFormatters.formatDuration(configuration.longestActivityDuration))
            }
            if let firstPickup = configuration.firstPickup {
                MetricRow(label: "First Pickup", value: PulseFormatters.formatTime(firstPickup))
            }

            Divider().opacity(0.35)

            Text("Top Apps")
                .font(.subheadline)
                .fontWeight(.semibold)

            if configuration.totalDuration == 0,
               configuration.totalPickups == 0,
               configuration.totalNotifications == 0,
               configuration.longestActivityDuration == 0,
               configuration.firstPickup == nil,
               configuration.topApps.isEmpty,
               configuration.topCategories.isEmpty,
               configuration.topWebsites.isEmpty {
                Text("No activity data yet. Usage appears after monitoring begins.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            if configuration.topApps.isEmpty {
                Text("No activity recorded yet.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(Array(configuration.topApps.enumerated()), id: \.offset) { index, app in
                    RankedAppRow(
                        rank: index + 1,
                        name: app.name,
                        detail: "\(PulseFormatters.formatDuration(app.duration)) · \(app.pickups) pickups · \(app.notifications) notifs"
                    )
                }
            }

            if !configuration.topCategories.isEmpty {
                Divider().opacity(0.35)
                Text("Top Categories")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(Array(configuration.topCategories.enumerated()), id: \.offset) { index, category in
                    RankedAppRow(
                        rank: index + 1,
                        name: category.name,
                        detail: PulseFormatters.formatDuration(category.duration)
                    )
                }
            }

            if !configuration.topWebsites.isEmpty {
                Divider().opacity(0.35)
                Text("Top Websites")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(Array(configuration.topWebsites.enumerated()), id: \.offset) { index, site in
                    RankedAppRow(
                        rank: index + 1,
                        name: site.name,
                        detail: PulseFormatters.formatDuration(site.duration)
                    )
                }
            }
        }
        .font(.callout)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct RankedAppRow: View {
    let rank: Int
    let name: String
    let detail: String

    var body: some View {
        HStack {
            Text("\(rank)")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)
            Text(name)
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseSummaryConfiguration {
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let totalPickups: Int
    let topApps: [PulseAppUsage]
}

private struct PulseTodayConfiguration {
    let totalDuration: TimeInterval
    let totalPickups: Int
    let totalNotifications: Int
    let longestActivityDuration: TimeInterval
    let firstPickup: Date?
    let topApps: [PulseAppUsage]
    let topCategories: [PulseCategoryUsage]
    let topWebsites: [PulseWebsiteUsage]
}

private struct PulseAppUsage {
    let name: String
    let duration: TimeInterval
    let pickups: Int
    let notifications: Int
}

private struct PulseCategoryUsage {
    let name: String
    let duration: TimeInterval
}

private struct PulseWebsiteUsage {
    let name: String
    let duration: TimeInterval
}

private struct PulseActivityAggregate {
    var totalDuration: TimeInterval = 0
    var totalPickups: Int = 0
    var totalNotifications: Int = 0
    var segmentCount: Int = 0
    var longestActivityDuration: TimeInterval = 0
    var firstPickup: Date?
    var appUsage: [ManagedSettings.Application: AppUsageAggregate] = [:]
    var categoryUsage: [ManagedSettings.ActivityCategory: TimeInterval] = [:]
    var webUsage: [ManagedSettings.WebDomain: TimeInterval] = [:]

    static func aggregate(from data: DeviceActivityResults<DeviceActivityData>) async -> PulseActivityAggregate {
        var aggregate = PulseActivityAggregate()
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                aggregate.segmentCount += 1
                aggregate.totalDuration += segment.totalActivityDuration
                aggregate.totalPickups += segment.totalPickupsWithoutApplicationActivity

                if let firstPickup = segment.firstPickup {
                    if let currentFirst = aggregate.firstPickup {
                        aggregate.firstPickup = min(currentFirst, firstPickup)
                    } else {
                        aggregate.firstPickup = firstPickup
                    }
                }

                if let longestActivity = segment.longestActivity?.duration {
                    aggregate.longestActivityDuration = max(aggregate.longestActivityDuration, longestActivity)
                }

                for await category in segment.categories {
                    aggregate.categoryUsage[category.category, default: 0] += category.totalActivityDuration

                    for await app in category.applications {
                        var entry = aggregate.appUsage[app.application, default: AppUsageAggregate()]
                        entry.duration += app.totalActivityDuration
                        entry.pickups += app.numberOfPickups
                        entry.notifications += app.numberOfNotifications
                        aggregate.appUsage[app.application] = entry

                        aggregate.totalPickups += app.numberOfPickups
                        aggregate.totalNotifications += app.numberOfNotifications
                    }

                    for await site in category.webDomains {
                        aggregate.webUsage[site.webDomain, default: 0] += site.totalActivityDuration
                    }
                }
            }
        }
        return aggregate
    }

    func averageDuration(divisor: Int) -> TimeInterval {
        guard divisor > 0 else { return 0 }
        return totalDuration / Double(divisor)
    }

    func topAppsSortedByPickups(limit: Int) -> [PulseAppUsage] {
        let sorted = appUsage
            .map { app, usage in
                PulseAppUsage(
                    name: PulseFormatters.appName(app),
                    duration: usage.duration,
                    pickups: usage.pickups,
                    notifications: usage.notifications
                )
            }
            .sorted { lhs, rhs in
                if lhs.pickups == rhs.pickups {
                    return lhs.duration > rhs.duration
                }
                return lhs.pickups > rhs.pickups
            }
        return Array(sorted.prefix(limit))
    }

    func topAppsSortedByDuration(limit: Int) -> [PulseAppUsage] {
        let sorted = appUsage
            .map { app, usage in
                PulseAppUsage(
                    name: PulseFormatters.appName(app),
                    duration: usage.duration,
                    pickups: usage.pickups,
                    notifications: usage.notifications
                )
            }
            .sorted { lhs, rhs in
                if lhs.duration == rhs.duration {
                    return lhs.pickups > rhs.pickups
                }
                return lhs.duration > rhs.duration
            }
        return Array(sorted.prefix(limit))
    }

    func topCategories(limit: Int) -> [PulseCategoryUsage] {
        let sorted = categoryUsage
            .map { category, duration in
                PulseCategoryUsage(
                    name: PulseFormatters.categoryName(category),
                    duration: duration
                )
            }
            .sorted { $0.duration > $1.duration }
        return Array(sorted.prefix(limit))
    }

    func topWebsites(limit: Int) -> [PulseWebsiteUsage] {
        let sorted = webUsage
            .map { domain, duration in
                PulseWebsiteUsage(
                    name: PulseFormatters.webDomainName(domain),
                    duration: duration
                )
            }
            .sorted { $0.duration > $1.duration }
        return Array(sorted.prefix(limit))
    }

    struct AppUsageAggregate {
        var duration: TimeInterval = 0
        var pickups: Int = 0
        var notifications: Int = 0
    }
}

private enum PulseFormatters {
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "0m" }
        return durationFormatter.string(from: duration) ?? "0m"
    }

    static func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func appName(_ app: ManagedSettings.Application) -> String {
        app.localizedDisplayName ?? app.bundleIdentifier ?? "Unknown App"
    }

    static func categoryName(_ category: ManagedSettings.ActivityCategory) -> String {
        category.localizedDisplayName ?? "Other"
    }

    static func webDomainName(_ domain: ManagedSettings.WebDomain) -> String {
        domain.domain ?? "Unknown Site"
    }
}

private extension DeviceActivityReport.Context {
    static let weeklySummary = Self("weeklySummary")
    static let dailySummary = Self("dailySummary")
    static let todayReport = Self("todayReport")
}
