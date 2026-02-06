import Foundation
import WidgetKit

struct WidgetSharedContainer {
    let appGroupID: String

    static let `default` = WidgetSharedContainer(appGroupID: WidgetSharedConstants.appGroupID)

    var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    var snapshotURL: URL? {
        containerURL?.appendingPathComponent(WidgetSharedConstants.snapshotFileName)
    }
}

final class WidgetSnapshotStore {
    private let container: WidgetSharedContainer
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(container: WidgetSharedContainer = .default) {
        self.container = container
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadSnapshot() -> WidgetSnapshot {
        guard let url = container.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    func saveSnapshot(_ snapshot: WidgetSnapshot) {
        guard let url = container.snapshotURL else { return }
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            return
        }
        WidgetSharedConstants.allWidgetKinds.forEach { kind in
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }
}
