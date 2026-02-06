import Foundation
import WidgetKit

struct WidgetSharedContainer {
    let appGroupID: String
    private let fixedContainerURL: URL?

    init(appGroupID: String, fixedContainerURL: URL? = nil) {
        self.appGroupID = appGroupID
        self.fixedContainerURL = fixedContainerURL
    }

    static let `default` = WidgetSharedContainer(appGroupID: WidgetSharedConstants.appGroupID)

    var containerURL: URL? {
        fixedContainerURL ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    var snapshotURL: URL? {
        containerURL?.appendingPathComponent(WidgetSharedConstants.snapshotFileName)
    }

    var snapshotBackupURL: URL? {
        containerURL?.appendingPathComponent(WidgetSharedConstants.snapshotBackupFileName)
    }
}

final class WidgetSnapshotStore {
    private static let ioQueue = DispatchQueue(label: "com.iisacc.timescopes.widgetSnapshotStore.io")

    private let container: WidgetSharedContainer
    private let reloadTimelines: () -> Void
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        container: WidgetSharedContainer = .default,
        reloadTimelines: @escaping () -> Void = {
            WidgetCenter.shared.reloadAllTimelines()
        }
    ) {
        self.container = container
        self.reloadTimelines = reloadTimelines
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadSnapshot() -> WidgetSnapshot {
        Self.ioQueue.sync {
            loadSnapshotFromDisk()
        }
    }

    func saveSnapshot(_ snapshot: WidgetSnapshot, requestTimelineReload: Bool = true) {
        let didSave = Self.ioQueue.sync {
            saveSnapshotToDisk(snapshot)
        }
        guard didSave, requestTimelineReload else { return }
        reloadWidgetTimelines()
    }

    func updateSnapshot(requestTimelineReload: Bool = true, _ transform: (WidgetSnapshot) -> WidgetSnapshot) {
        let didSave = Self.ioQueue.sync {
            mutateSnapshotOnDisk(transform)
        }
        guard didSave, requestTimelineReload else { return }
        reloadWidgetTimelines()
    }

    private func loadSnapshotFromDisk() -> WidgetSnapshot {
        guard let url = container.snapshotURL else { return .empty }
        let backupURL = container.snapshotBackupURL

        var snapshot: WidgetSnapshot?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        coordinator.coordinate(readingItemAt: url, options: [.withoutChanges], error: &coordinationError) { readURL in
            snapshot = decodeSnapshot(at: readURL)
        }

        // Fallback for first-run / uncoordinated access paths.
        if let snapshot {
            return snapshot
        }
        if let snapshot = decodeSnapshot(at: url) {
            return snapshot
        }
        if let backupURL, let backupSnapshot = decodeSnapshot(at: backupURL) {
            _ = encodeSnapshot(backupSnapshot, at: url)
            return backupSnapshot
        }
        return .empty
    }

    private func saveSnapshotToDisk(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = container.snapshotURL else { return false }
        let backupURL = container.snapshotBackupURL
        guard ensureParentDirectory(for: url) else { return false }
        if let backupURL, !ensureParentDirectory(for: backupURL) {
            return false
        }

        var didWrite = false
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        coordinator.coordinate(writingItemAt: url, options: [.forMerging], error: &coordinationError) { writeURL in
            didWrite = encodeSnapshot(snapshot, at: writeURL)
        }
        if didWrite {
            return writeBackupSnapshot(snapshot, backupURL: backupURL)
        }
        guard encodeSnapshot(snapshot, at: url) else { return false }
        return writeBackupSnapshot(snapshot, backupURL: backupURL)
    }

    private func mutateSnapshotOnDisk(_ transform: (WidgetSnapshot) -> WidgetSnapshot) -> Bool {
        guard let url = container.snapshotURL else { return false }
        let backupURL = container.snapshotBackupURL
        guard ensureParentDirectory(for: url) else { return false }
        if let backupURL, !ensureParentDirectory(for: backupURL) {
            return false
        }

        var didWrite = false
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        coordinator.coordinate(writingItemAt: url, options: [.forMerging], error: &coordinationError) { writeURL in
            let current = decodeSnapshot(at: writeURL)
                ?? decodeSnapshot(at: url)
                ?? (backupURL.flatMap { decodeSnapshot(at: $0) })
                ?? .empty
            let updated = transform(current)
            didWrite = encodeSnapshot(updated, at: writeURL) && writeBackupSnapshot(updated, backupURL: backupURL)
        }
        if didWrite {
            return true
        }
        let current = decodeSnapshot(at: url)
            ?? (backupURL.flatMap { decodeSnapshot(at: $0) })
            ?? .empty
        let updated = transform(current)
        guard encodeSnapshot(updated, at: url) else { return false }
        return writeBackupSnapshot(updated, backupURL: backupURL)
    }

    private func decodeSnapshot(at url: URL) -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    private func encodeSnapshot(_ snapshot: WidgetSnapshot, at url: URL) -> Bool {
        guard let data = try? encoder.encode(snapshot) else { return false }
        do {
            try data.write(to: url, options: [.atomic])
            return true
        } catch {
            return false
        }
    }

    private func ensureParentDirectory(for url: URL) -> Bool {
        let parent = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }

    private func writeBackupSnapshot(_ snapshot: WidgetSnapshot, backupURL: URL?) -> Bool {
        guard let backupURL else { return true }
        return encodeSnapshot(snapshot, at: backupURL)
    }

    private func reloadWidgetTimelines() {
        reloadTimelines()
    }
}
