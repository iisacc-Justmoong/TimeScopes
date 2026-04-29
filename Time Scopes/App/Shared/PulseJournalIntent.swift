import AppIntents
import Foundation

@available(iOS 17.0, *)
struct AddPulseJournalEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pulse Entry"
    static var description = IntentDescription("Open the Pulse journal composer. Provided entry text is saved directly.")
    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Entry Text")
    var note: String?

    func perform() async throws -> some IntentResult {
        if let note, PulseJournalWidgetAction.appendEntry(note: note) {
            return .result()
        }
        PulseJournalWidgetAction.requestOpenComposer()
        return .result()
    }
}
