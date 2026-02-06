import Darwin
import Foundation

struct PulseJournalStoredEntry: Codable, Equatable {
    let id: UUID
    let date: Date
    let note: String
}

enum PulseJournalStorageCoordinator {
    static func sharedDefaults() -> UserDefaults {
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSharedConstants.appGroupID) != nil,
              let defaults = UserDefaults(suiteName: WidgetSharedConstants.appGroupID) else {
            return .standard
        }
        return defaults
    }

    static func loadEntries(defaults: UserDefaults, storeKey: String) -> [PulseJournalStoredEntry] {
        withExclusiveLock(storeKey: storeKey) {
            decodeEntries(from: defaults.data(forKey: storeKey))
        }
    }

    @discardableResult
    static func saveEntries(_ entries: [PulseJournalStoredEntry], defaults: UserDefaults, storeKey: String) -> Bool {
        withExclusiveLock(storeKey: storeKey) {
            guard let data = encodeEntries(entries) else { return false }
            defaults.set(data, forKey: storeKey)
            return true
        }
    }

    static func mutateEntries(
        defaults: UserDefaults,
        storeKey: String,
        transform: (inout [PulseJournalStoredEntry]) -> Void
    ) -> [PulseJournalStoredEntry]? {
        withExclusiveLock(storeKey: storeKey) {
            var entries = decodeEntries(from: defaults.data(forKey: storeKey))
            transform(&entries)
            guard let data = encodeEntries(entries) else {
                return nil
            }
            defaults.set(data, forKey: storeKey)
            return entries
        }
    }

    static func withExclusiveLock<T>(storeKey: String, body: () -> T) -> T {
        let lockURL = lockFileURL(storeKey: storeKey)
        let lockPath = lockURL.path
        if !FileManager.default.fileExists(atPath: lockPath) {
            FileManager.default.createFile(atPath: lockPath, contents: nil)
        }

        let fileDescriptor = open(lockPath, O_RDWR | O_CREAT, 0o600)
        guard fileDescriptor >= 0 else {
            return body()
        }
        defer {
            close(fileDescriptor)
        }

        guard flock(fileDescriptor, LOCK_EX) == 0 else {
            return body()
        }
        defer {
            flock(fileDescriptor, LOCK_UN)
        }
        return body()
    }

    private static func lockFileURL(storeKey: String) -> URL {
        let baseDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSharedConstants.appGroupID)
            ?? FileManager.default.temporaryDirectory
        let encoded = Data(storeKey.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return baseDirectory.appendingPathComponent("pulse_journal_\(encoded).lock")
    }

    private static func decodeEntries(from data: Data?) -> [PulseJournalStoredEntry] {
        guard let data else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PulseJournalStoredEntry].self, from: data)) ?? []
    }

    private static func encodeEntries(_ entries: [PulseJournalStoredEntry]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(entries)
    }
}
