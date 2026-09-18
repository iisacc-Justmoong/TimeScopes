import AppIntents
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 18.0, *)
struct TimeScopesPulseJournalControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: WidgetSharedConstants.pulseJournalControlKind) {
            ControlWidgetButton(action: AddPulseJournalEntryIntent()) {
                Label("Add Entry", systemImage: "square.and.pencil")
            }
        }
        .displayName("Add Pulse Entry")
        .description("Open Time Scopes and create a new Pulse journal entry.")
    }
}
