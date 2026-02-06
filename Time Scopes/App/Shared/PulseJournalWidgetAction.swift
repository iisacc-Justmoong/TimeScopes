import Foundation

enum PulseJournalWidgetAction {
    static let openComposerRequestKey = "PulseJournalWidget.OpenComposerRequest"

    private static var defaults: UserDefaults {
        PulseJournalStorageCoordinator.sharedDefaults()
    }

    static var hasPendingOpenComposerRequest: Bool {
        defaults.object(forKey: openComposerRequestKey) != nil
    }

    static func requestOpenComposer() {
        defaults.set(Date().timeIntervalSince1970, forKey: openComposerRequestKey)
    }

    static func consumeOpenComposerRequest() -> Bool {
        guard hasPendingOpenComposerRequest else { return false }
        defaults.removeObject(forKey: openComposerRequestKey)
        return true
    }

    @discardableResult
    static func appendEntry(note: String, date: Date = Date()) -> Bool {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }

        guard let updatedEntries = PulseJournalStorageCoordinator.mutateEntries(
            defaults: defaults,
            storeKey: WidgetSharedConstants.pulseJournalEntriesStoreKey,
            transform: { entries in
                entries.insert(
                    PulseJournalStoredEntry(
                        id: UUID(),
                        date: date,
                        note: trimmed
                    ),
                    at: 0
                )
            }
        ) else {
            return false
        }

        syncWidgetSnapshot(with: Array(updatedEntries.prefix(3)))
        NotificationCenter.default.post(name: .pulseJournalDidChange, object: nil)
        return true
    }

    private static func syncWidgetSnapshot(with entries: [PulseJournalStoredEntry]) {
        let recentEntries = entries.map {
            WidgetSnapshot.Pulse.JournalEntry(date: $0.date, note: $0.note)
        }
        let widgetStore = WidgetSnapshotStore()
        widgetStore.updateSnapshot { current in
            let pulse = current.pulse
            return WidgetSnapshot(
                updatedAt: Date(),
                profile: current.profile,
                elapsed: current.elapsed,
                milestones: current.milestones,
                highlights: current.highlights,
                daily: current.daily,
                pulse: WidgetSnapshot.Pulse(
                    todaySeries: pulse.todaySeries,
                    todayMax: pulse.todayMax,
                    currentFraction: pulse.currentFraction,
                    weeklyDays: pulse.weeklyDays,
                    weeklyPatternText: pulse.weeklyPatternText,
                    weeklyPeakText: pulse.weeklyPeakText,
                    weeklyLowText: pulse.weeklyLowText,
                    prescriptions: pulse.prescriptions,
                    journalPrompt: pulse.journalPrompt,
                    recentEntries: recentEntries
                )
            )
        }
    }
}
