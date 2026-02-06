import AppIntents

@available(iOS 17.0, *)
struct PulseJournalAppShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddPulseJournalEntryIntent(),
            phrases: [
                "Add a pulse journal entry in \(.applicationName)",
                "Write in pulse journal using \(.applicationName)",
            ],
            shortTitle: "Add Entry",
            systemImageName: "square.and.pencil"
        )
    }
}
