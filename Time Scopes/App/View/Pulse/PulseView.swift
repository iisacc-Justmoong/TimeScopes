//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import SwiftUI

struct PulseView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var eventProvider = CalendarEventProvider()
    @StateObject var reminderProvider = ReminderProvider()
    @StateObject var journalStore = PulseJournalStore()

    @State var isPresentingJournal = false
    @State var journalDraft = ""
    @State var editingEntry: PulseJournalEntry?
    @State var entryToDelete: PulseJournalEntry?
    @State var isConfirmingDelete = false
    @State var currentPrompt = ""

    let calendar = Calendar.autoupdatingCurrent
    let widgetStore = WidgetSnapshotStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    if let message = dataStatusMessage {
                        PulseCallout(title: "Data Status", detail: message)
                    }
                    todayStructureCard
                    weeklyRhythmCard
                    prescriptionCard
                    journalCard
                }
                .padding()
            }
            .glassScreen()
        }
        .onAppear {
            refreshPrompt()
            syncPulseWidgetSnapshot()
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            refreshData()
            syncPulseWidgetSnapshot()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshData()
                syncPulseWidgetSnapshot()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshData()
            syncPulseWidgetSnapshot()
        }
        .onReceive(journalStore.$entries) { _ in
            syncPulseWidgetSnapshot()
        }
        .sheet(isPresented: $isPresentingJournal) {
            PulseJournalComposer(
                title: editingEntry == nil ? "New Entry" : "Edit Entry",
                saveLabel: editingEntry == nil ? "Save" : "Update",
                prompt: currentPrompt,
                draft: $journalDraft
            ) { note in
                if let editingEntry {
                    journalStore.updateEntry(id: editingEntry.id, note: note)
                } else {
                    journalStore.addEntry(note: note)
                }
                journalDraft = ""
                editingEntry = nil
                isPresentingJournal = false
            }
        }
        .onChange(of: isPresentingJournal) { isPresented in
            if !isPresented {
                journalDraft = ""
                editingEntry = nil
            }
        }
        .confirmationDialog(
            "Delete entry?",
            isPresented: $isConfirmingDelete,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                journalStore.deleteEntry(id: entry.id)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        }
    }
}

#Preview {
    PulseView()
        .environmentObject(UserData())
}
