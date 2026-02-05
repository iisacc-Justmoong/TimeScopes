//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import SwiftUI

struct PulseView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var userData: UserData
    @StateObject private var eventProvider = CalendarEventProvider()
    @StateObject private var reminderProvider = ReminderProvider()
    @StateObject private var journalStore = PulseJournalStore()

    @State private var isPresentingJournal = false
    @State private var journalDraft = ""
    @State private var editingEntry: PulseJournalEntry?
    @State private var entryToDelete: PulseJournalEntry?
    @State private var isConfirmingDelete = false

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    if let message = dataStatusMessage {
                        PulseCallout(title: "Data Status", detail: message)
                    }
                    todayStructureCard
                    weeklyRhythmCard
                    prescriptionCard
                    journalCard
                }
                .padding()
            }
            .glassScreen()
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            refreshData()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshData()
        }
        .sheet(isPresented: $isPresentingJournal) {
            PulseJournalComposer(
                title: editingEntry == nil ? "New Entry" : "Edit Entry",
                saveLabel: editingEntry == nil ? "Save" : "Update",
                draft: $journalDraft
            ) { note in
                if let editingEntry {
                    journalStore.updateEntry(id: editingEntry.id, note: note)
                } else {
                    journalStore.addEntry(note: note)
                }
                journalDraft = ""
                editingEntry = nil
                isPresentingJournal = false
            }
        }
        .onChange(of: isPresentingJournal) { isPresented in
            if !isPresented {
                journalDraft = ""
                editingEntry = nil
            }
        }
        .confirmationDialog(
            "Delete entry?",
            isPresented: $isConfirmingDelete,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                journalStore.deleteEntry(id: entry.id)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pulse")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Structure, rhythm, and actions for your time.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    private var todayStructureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Today Structure",
                subtitle: "A functional map of the next 24 hours."
            )
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(todayMetrics) { metric in
                    PulseMetricCard(metric: metric)
                }
            }
        }
        .glassCard(showBorder: false)
    }

    private var weeklyRhythmCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Weekly Rhythm",
                subtitle: "Pressure and energy across the week."
            )
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(weeklyRhythm) { day in
                    PulseDayBar(day: day)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PulseCallout(
                title: "Pattern",
                detail: weeklyPatternText
            )
        }
        .glassCard(showBorder: false)
    }

    private var prescriptionCard: some View {
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
        .glassCard(showBorder: false)
    }

    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Daily Journal",
                subtitle: "Capture what moved the day."
            )
            VStack(alignment: .leading, spacing: 10) {
                Text("Prompt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("What single change would make tomorrow feel lighter?")
                    .font(.callout)
            }
            Button("Write Entry") {
                beginNewEntry()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
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
                            onDelete: { promptDelete(entry) }
                        )
                    }
                }
            }
        }
        .glassCard(showBorder: false)
    }

    private var todayMetrics: [PulseMetric] {
        let today = Date()
        let dayInterval = dayInterval(for: today)
        let events = eventProvider.events(on: today).filter { !$0.isAllDay }
        let reminders = reminderProvider.reminders(on: today)

        let fixed = events.reduce(0) { total, event in
            total + clampedDuration(for: event, in: dayInterval)
        }
        let eventBuffers = Double(events.count) * 10 * 60
        let reminderBuffers = Double(reminders.count) * 6 * 60
        let recovery = min(2 * 3600, eventBuffers + reminderBuffers)

        let workTarget = max(0, Double(userData.workHoursPerDay) * 3600)
        let sleepTarget = max(0, Double(userData.sleepHoursPerDay) * 3600)
        let flexible = max(0, workTarget - fixed)
        let unallocated = max(0, (24 * 3600) - (fixed + recovery + flexible))

        let totalDay = 24 * 3600.0

        return [
            PulseMetric(
                title: "Fixed Time",
                duration: fixed,
                detail: "\(events.count) events today",
                progress: fixed / totalDay,
                tint: .orange
            ),
            PulseMetric(
                title: "Flexible Time",
                duration: flexible,
                detail: "Work target \(userData.workHoursPerDay)h",
                progress: flexible / totalDay,
                tint: .mint
            ),
            PulseMetric(
                title: "Recovery Time",
                duration: recovery,
                detail: "Buffers from events and tasks",
                progress: recovery / totalDay,
                tint: .blue
            ),
            PulseMetric(
                title: "Unallocated",
                duration: unallocated,
                detail: "Sleep target \(userData.sleepHoursPerDay)h",
                progress: unallocated / totalDay,
                tint: .purple
            )
        ]
    }

    private var weeklyRhythm: [PulseDayIntensity] {
        let today = Date()
        let weekStart = weekInterval(for: today).start
        var dayLoads: [Double] = []
        var days: [PulseDayIntensity] = []

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let interval = dayInterval(for: day)
            let events = eventProvider.events(on: day).filter { !$0.isAllDay }
            let reminders = reminderProvider.reminders(on: day)
            let eventMinutes = events.reduce(0.0) { total, event in
                total + clampedDuration(for: event, in: interval) / 60
            }
            let reminderMinutes = Double(reminders.count) * 15
            let load = eventMinutes + reminderMinutes
            dayLoads.append(load)
        }

        let maxLoad = dayLoads.max() ?? 0
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let label = PulseFormatters.weekdayFormatter.string(from: day)
            let load = offset < dayLoads.count ? dayLoads[offset] : 0
            let intensity = maxLoad > 0 ? load / maxLoad : 0
            days.append(PulseDayIntensity(day: label, intensity: intensity))
        }

        return days
    }

    private var prescriptions: [PulsePrescription] {
        var items: [PulsePrescription] = []
        let today = Date()
        let dayInterval = dayInterval(for: today)
        let events = eventProvider.events(on: today).filter { !$0.isAllDay }
        let reminders = reminderProvider.reminders(on: today)

        if let longest = events.max(by: { clampedDuration(for: $0, in: dayInterval) < clampedDuration(for: $1, in: dayInterval) }) {
            let duration = clampedDuration(for: longest, in: dayInterval)
            if duration >= 90 * 60 {
                items.append(
                    PulsePrescription(
                        focus: "Recovery",
                        title: "Insert a 25m reset after \(longest.title)",
                        detail: "Long sessions benefit from a deliberate buffer.",
                        impact: "Protects 25m"
                    )
                )
            }
        }

        if reminders.count >= 4 {
            items.append(
                PulsePrescription(
                    focus: "Flex",
                    title: "Batch \(reminders.count) quick tasks into one block",
                    detail: "Reduce context switching during the afternoon.",
                    impact: "\(reminders.count) items"
                )
            )
        }

        if let peak = weeklyPeakShiftSuggestion() {
            items.append(peak)
        }

        if items.isEmpty {
            items.append(
                PulsePrescription(
                    focus: "Focus",
                    title: "Reserve one 45m deep-work block",
                    detail: "Protect a window for your most important task.",
                    impact: "45m"
                )
            )
        }

        return Array(items.prefix(3))
    }

    private var recentEntries: [PulseJournalEntry] {
        journalStore.recentEntries(limit: 3)
    }

    private var dataStatusMessage: String? {
        var messages: [String] = []
        if !eventProvider.hasAccess {
            messages.append("Calendar access not granted.")
        } else if !eventProvider.hasICloudCalendars {
            messages.append("No iCloud calendars found.")
        }

        if !reminderProvider.hasAccess {
            messages.append("Reminders access not granted.")
        } else if !reminderProvider.hasICloudReminders {
            messages.append("No iCloud reminder lists found.")
        }

        return messages.isEmpty ? nil : messages.joined(separator: " ")
    }

    private var weeklyPatternText: String {
        let intensities = weeklyRhythm
        guard let maxDay = intensities.max(by: { $0.intensity < $1.intensity }),
              let minDay = intensities.min(by: { $0.intensity < $1.intensity }),
              maxDay.intensity > 0 else {
            return "Not enough data yet. Add events or reminders to reveal your weekly rhythm."
        }
        if maxDay.day == minDay.day {
            return "Your week is balanced so far. Keep the current distribution."
        }
        return "\(maxDay.day) is your peak-load day. Consider moving one deep task to \(minDay.day)."
    }

    private func weeklyPeakShiftSuggestion() -> PulsePrescription? {
        let intensities = weeklyRhythm
        guard let maxDay = intensities.max(by: { $0.intensity < $1.intensity }),
              let minDay = intensities.min(by: { $0.intensity < $1.intensity }) else {
            return nil
        }
        guard maxDay.intensity - minDay.intensity >= 0.35 else {
            return nil
        }
        return PulsePrescription(
            focus: "Focus",
            title: "Move one deep block from \(maxDay.day) to \(minDay.day)",
            detail: "Rebalancing reduces peak-day overload.",
            impact: "Load -18%"
        )
    }

    private func refreshData() {
        let interval = weekInterval(for: Date())
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private func weekInterval(for date: Date) -> DateInterval {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval
        }
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private func clampedDuration(for event: CalendarEventItem, in interval: DateInterval) -> TimeInterval {
        let start = max(event.startDate, interval.start)
        let end = min(event.endDate, interval.end)
        return max(0, end.timeIntervalSince(start))
    }

    private func beginNewEntry() {
        editingEntry = nil
        journalDraft = ""
        isPresentingJournal = true
    }

    private func beginEdit(_ entry: PulseJournalEntry) {
        editingEntry = entry
        journalDraft = entry.note
        isPresentingJournal = true
    }

    private func promptDelete(_ entry: PulseJournalEntry) {
        entryToDelete = entry
        isConfirmingDelete = true
    }
}

private struct PulseMetric: Identifiable {
    let id = UUID()
    let title: String
    let duration: TimeInterval
    let detail: String
    let progress: Double
    let tint: Color
}

private struct PulseDayIntensity: Identifiable {
    let id = UUID()
    let day: String
    let intensity: Double
}

private struct PulsePrescription: Identifiable {
    let id = UUID()
    let focus: String
    let title: String
    let detail: String
    let impact: String
}

private struct PulseSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseMetricCard: View {
    let metric: PulseMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(metric.title)
                    .font(.subheadline)
                Spacer()
                Text(PulseFormatters.formatDuration(metric.duration))
                    .font(.headline)
            }
            ProgressView(value: metric.progress)
                .tint(metric.tint)
            Text(metric.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseDayBar: View {
    let day: PulseDayIntensity

    private var height: CGFloat {
        max(16, 110 * day.intensity)
    }

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.75))
                .frame(width: 18, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
            Text(day.day)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulsePrescriptionRow: View {
    let prescription: PulsePrescription

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PulseTag(text: prescription.focus)
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(prescription.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(prescription.impact)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.2))
            )
            .foregroundStyle(Color.accentColor)
    }
}

private struct PulseCallout: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.callout)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseJournalRow: View {
    let entry: PulseJournalEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(PulseFormatters.timeFormatter.string(from: entry.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)
            Text(entry.note)
                .font(.callout)
            Spacer(minLength: 0)
            VStack {
                Spacer(minLength: 0)
                Menu {
                    Button("Edit") {
                        onEdit()
                    }
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseJournalComposer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let saveLabel: String
    @Binding var draft: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Write one clear sentence about your day.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextEditor(text: $draft)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                    )
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveLabel) {
                        onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private enum PulseFormatters {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "0m" }
        return durationFormatter.string(from: duration) ?? "0m"
    }
}

#Preview {
    PulseView()
        .environmentObject(UserData())
}
