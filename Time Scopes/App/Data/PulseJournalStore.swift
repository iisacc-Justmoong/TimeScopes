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

extension Notification.Name {
    static let pulseJournalDidChange = Notification.Name("PulseJournalDidChange")
}

@MainActor
final class PulseJournalStore: ObservableObject {
    @Published private(set) var entries: [PulseJournalEntry] = []

    private let storeKey = "PulseJournalEntries"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let defaults: UserDefaults
    private let legacyDefaults = UserDefaults.standard
    private var observers: [NSObjectProtocol] = []

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.encoder = encoder
        self.decoder = decoder
        self.defaults = UserDefaults(suiteName: WidgetSharedConstants.appGroupID) ?? .standard
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
        let center = NotificationCenter.default
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
        observers.append(
            center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.load()
                }
            }
        )
    }

    func addEntry(note: String, date: Date = Date()) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = PulseJournalEntry(id: UUID(), date: date, note: trimmed)
        entries.insert(entry, at: 0)
        persist()
    }

    func updateEntry(id: UUID, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let existing = entries[index]
        entries[index] = PulseJournalEntry(id: existing.id, date: existing.date, note: trimmed)
        persist()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
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
        guard let data = defaults.data(forKey: storeKey) else {
            entries = []
            return
        }
        do {
            entries = try decoder.decode([PulseJournalEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(entries)
            defaults.set(data, forKey: storeKey)
            NotificationCenter.default.post(name: .pulseJournalDidChange, object: nil)
        } catch {
            return
        }
    }

    private func migrateIfNeeded() {
        guard defaults.object(forKey: storeKey) == nil,
              let legacyData = legacyDefaults.data(forKey: storeKey) else {
            return
        }
        defaults.set(legacyData, forKey: storeKey)
    }
}
