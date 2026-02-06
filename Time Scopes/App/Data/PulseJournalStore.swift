//
//  PulseJournalStore.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import Foundation
import UIKit

struct PulseJournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let note: String
}

@MainActor
final class PulseJournalStore: ObservableObject {
    @Published private(set) var entries: [PulseJournalEntry] = []

    private let storeKey: String
    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let observeLifecycle: Bool
    private let foregroundNotificationName: Notification.Name
    private var observers: [NSObjectProtocol] = []

    init(
        defaults: UserDefaults? = nil,
        legacyDefaults: UserDefaults = .standard,
        storeKey: String = WidgetSharedConstants.pulseJournalEntriesStoreKey,
        notificationCenter: NotificationCenter = .default,
        observeLifecycle: Bool = true,
        foregroundNotificationName: Notification.Name = UIApplication.willEnterForegroundNotification
    ) {
        self.defaults = defaults ?? PulseJournalStorageCoordinator.sharedDefaults()
        self.legacyDefaults = legacyDefaults
        self.storeKey = storeKey
        self.notificationCenter = notificationCenter
        self.observeLifecycle = observeLifecycle
        self.foregroundNotificationName = foregroundNotificationName
        migrateIfNeeded()
        load()
        configureObservers()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func reload() {
        load()
    }

    private func configureObservers() {
        let center = notificationCenter
        observers.append(
            center.addObserver(
                forName: .pulseJournalDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.load()
                }
            }
        )
        observers.append(
            center.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: defaults,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.load()
                }
            }
        )
        if observeLifecycle {
            observers.append(
                center.addObserver(
                    forName: foregroundNotificationName,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in
                        self?.load()
                    }
                }
            )
        }
    }

    func addEntry(note: String, date: Date = Date()) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let updated = PulseJournalStorageCoordinator.mutateEntries(
            defaults: defaults,
            storeKey: storeKey,
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
            return
        }
        entries = updated.map(Self.makeEntry)
        notificationCenter.post(name: .pulseJournalDidChange, object: nil)
    }

    func updateEntry(id: UUID, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let updated = PulseJournalStorageCoordinator.mutateEntries(
            defaults: defaults,
            storeKey: storeKey,
            transform: { entries in
                guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
                let existing = entries[index]
                entries[index] = PulseJournalStoredEntry(id: existing.id, date: existing.date, note: trimmed)
            }
        ) else {
            return
        }
        entries = updated.map(Self.makeEntry)
        notificationCenter.post(name: .pulseJournalDidChange, object: nil)
    }

    func deleteEntry(id: UUID) {
        guard let updated = PulseJournalStorageCoordinator.mutateEntries(
            defaults: defaults,
            storeKey: storeKey,
            transform: { entries in
                entries.removeAll { $0.id == id }
            }
        ) else {
            return
        }
        entries = updated.map(Self.makeEntry)
        notificationCenter.post(name: .pulseJournalDidChange, object: nil)
    }

    func recentEntries(limit: Int) -> [PulseJournalEntry] {
        Array(entries.prefix(limit))
    }

    func entries(on date: Date, calendar: Calendar = .autoupdatingCurrent) -> [PulseJournalEntry] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return []
        }
        return entries.filter { $0.date >= start && $0.date < end }
    }

    private func load() {
        let stored = PulseJournalStorageCoordinator.loadEntries(defaults: defaults, storeKey: storeKey)
        entries = stored.map(Self.makeEntry)
    }

    private func migrateIfNeeded() {
        guard defaults.object(forKey: storeKey) == nil,
              let legacyData = legacyDefaults.data(forKey: storeKey) else {
            return
        }
        PulseJournalStorageCoordinator.withExclusiveLock(storeKey: storeKey) {
            guard defaults.object(forKey: storeKey) == nil else { return }
            defaults.set(legacyData, forKey: storeKey)
        }
    }

    private static func makeEntry(_ stored: PulseJournalStoredEntry) -> PulseJournalEntry {
        PulseJournalEntry(id: stored.id, date: stored.date, note: stored.note)
    }
}
