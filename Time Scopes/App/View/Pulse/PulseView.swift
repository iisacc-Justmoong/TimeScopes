//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import SwiftUI

struct PulseView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var eventProvider = CalendarEventProvider()
    @StateObject private var reminderProvider = ReminderProvider()
    @StateObject private var journalStore = PulseJournalStore()

    @State private var isPresentingJournal = false
    @State private var journalDraft = ""
    @State private var editingEntry: PulseJournalEntry?
    @State private var entryToDelete: PulseJournalEntry?
    @State private var isConfirmingDelete = false
    @State private var currentPrompt = ""

    private let calendar = Calendar.autoupdatingCurrent
    private let widgetStore = WidgetSnapshotStore()

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
