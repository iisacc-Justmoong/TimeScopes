import AppIntents
import Foundation

@available(iOS 17.0, *)
struct AddPulseJournalEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pulse Entry"
    static var description = IntentDescription("Open the pulse journal composer in Time Scopes.")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PulseJournalWidgetAction.requestOpenComposer()
        return .result()
    }
}
