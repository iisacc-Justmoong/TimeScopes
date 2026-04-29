//
//  PulseView+Sections.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

extension PulseView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pulse")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Structure, rhythm, and actions for your time.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    var todayStructureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Today Structure",
                subtitle: "A functional map of the next 24 hours."
            )
            PulseDayLineChart(
                values: todayLoadSeries,
                maxValue: todayLoadMax,
                currentFraction: currentTimeFraction
            )
            .frame(height: 160)
            HStack {
                Text("Event + task count per hour")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .id(PulseScrollTarget.todayStructure)
        .glassCard(showBorder: false)
    }

    var weeklyRhythmCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Weekly Rhythm",
                subtitle: "Pressure and energy across the week."
            )
            WeeklyRhythmChart(days: weeklyRhythm, highlightDay: todayWeekdayLabel)
            PulseCallout(
                title: "Pattern",
                detail: weeklyPatternText
            )
            weeklyDetailSection
        }
        .id(PulseScrollTarget.weeklyRhythm)
        .glassCard(showBorder: false)
    }

    var prescriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Actionable Prescriptions",
                subtitle: "Small shifts with measurable impact."
            )
            if prescriptions.isEmpty {
                Text("No prescriptions yet. Add events or reminders to personalize guidance.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(prescriptions.indices, id: \.self) { index in
                    PulsePrescriptionRow(prescription: prescriptions[index])
                    if index < prescriptions.count - 1 {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
        .id(PulseScrollTarget.prescriptions)
        .glassCard(showBorder: false)
    }

    var journalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Daily Journal",
                subtitle: "Capture what moved the day."
            )
            PulseJournalQuickEntry(draft: $quickEntryDraft) { note in
                journalStore.addEntry(note: note)
                quickEntryDraft = ""
            }
            if recentEntries.isEmpty {
                Text("No entries yet. Start with one sentence.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recentEntries) { entry in
                        PulseJournalRow(
                            entry: entry,
                            onEdit: { beginEdit(entry) },
                            onDelete: { confirmDelete(entry) }
                        )
                    }
                }
            }
        }
        .id(PulseScrollTarget.journal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(showBorder: false)
    }

    var weeklyDetailSection: some View {
        let summary = weeklySummary
        return VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                PulseSummaryCell(title: "Peak Day", value: summary.peakDayText)
                PulseSummaryCell(title: "Low Day", value: summary.lowDayText)
                PulseSummaryCell(title: "Week Events", value: summary.eventCountText)
                PulseSummaryCell(title: "Week Reminders", value: summary.reminderCountText)
                PulseSummaryCell(title: "Event Time", value: summary.eventTimeText)
                PulseSummaryCell(title: "Total Load", value: summary.totalLoadText)
                PulseSummaryCell(title: "Avg Load/Day", value: summary.averageLoadText)
                PulseSummaryCell(title: "Avg Reminders/Day", value: summary.averageRemindersText)
                PulseSummaryCell(title: "Distribution", value: summary.distributionText)
                PulseSummaryCell(title: "Free Time in Week", value: summary.freeTimeText)
            }
            if !weeklyTopEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Longest Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(weeklyTopEvents) { event in
                        PulseWeeklyEventRow(event: event)
                    }
                }
            }
        }
    }
}
