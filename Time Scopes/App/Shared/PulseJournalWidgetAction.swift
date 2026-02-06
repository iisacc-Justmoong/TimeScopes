import Foundation

enum PulseJournalWidgetAction {
    static let openComposerRequestKey = "PulseJournalWidget.OpenComposerRequest"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetSharedConstants.appGroupID) ?? .standard
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
}
