//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import SwiftUI

enum PulseScrollTarget: String {
    case todayStructure
    case weeklyRhythm
    case prescriptions
    case journal
}

struct PulseView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var deepLinkCenter: AppDeepLinkCenter
    @StateObject var eventProvider = CalendarEventProvider()
    @StateObject var reminderProvider = ReminderProvider()
    @StateObject var journalStore = PulseJournalStore()
    @StateObject var refreshTicker = SecondTicker()

    @State var isPresentingJournal = false
    @State var quickEntryDraft = ""
    @State var journalDraft = ""
    @State var editingEntry: PulseJournalEntry?
    @State var entryToDelete: PulseJournalEntry?
    @State var isConfirmingDelete = false
    @State var isViewVisible = false
    @State var lastPeriodicRefresh: Date = .distantPast

    let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                .onAppear {
                    scrollToDeepLinkIfNeeded(using: proxy)
                }
                .onChange(of: deepLinkCenter.route?.id) {
                    scrollToDeepLinkIfNeeded(using: proxy)
                }
            }
        }
        .onAppear {
            isViewVisible = true
            performPeriodicRefreshIfNeeded(at: Date(), force: true)
            presentComposerIfRequestedFromWidget()
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            performPeriodicRefreshIfNeeded(at: Date(), force: true)
            presentComposerIfRequestedFromWidget()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                performPeriodicRefreshIfNeeded(at: Date(), force: true)
                presentComposerIfRequestedFromWidget()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            performPeriodicRefreshIfNeeded(at: Date(), force: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pulseJournalComposeRequested)) { _ in
            presentComposerIfRequestedFromWidget()
        }
        .onReceive(refreshTicker.$now) { now in
            performPeriodicRefreshIfNeeded(at: now)
        }
        .onReceive(eventProvider.$events) { _ in
            syncPulseWidgetSnapshot()
        }
        .onReceive(reminderProvider.$reminders) { _ in
            syncPulseWidgetSnapshot()
        }
        .onReceive(reminderProvider.$allReminders) { _ in
            syncPulseWidgetSnapshot()
        }
        .onReceive(journalStore.$entries) { _ in
            syncPulseWidgetSnapshot()
        }
        .sheet(isPresented: $isPresentingJournal) {
            PulseJournalComposer(
                title: editingEntry == nil ? "New Entry" : "Edit Entry",
                saveLabel: editingEntry == nil ? "Save" : "Update",
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
        .onChange(of: isPresentingJournal) { _, isPresented in
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
        .onDisappear {
            isViewVisible = false
        }
    }
}

#Preview {
    PulseView()
        .environmentObject(AppDeepLinkCenter())
        .environmentObject(UserData())
}
