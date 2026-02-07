import Foundation

struct WidgetSnapshotPatch: Sendable {
    let updatedAt: Date
    let requestTimelineReload: Bool
    let profile: WidgetSnapshot.Profile?
    let profileName: String?
    let profileAge: Int?
    let elapsed: WidgetSnapshot.Elapsed?
    let milestones: WidgetSnapshot.Milestones?
    let highlights: WidgetSnapshot.Highlights?
    let daily: WidgetSnapshot.DailySummary?
    let pulse: WidgetSnapshot.Pulse?
    let pulseRecentEntries: [WidgetSnapshot.Pulse.JournalEntry]?

    init(
        updatedAt: Date,
        requestTimelineReload: Bool = true,
        profile: WidgetSnapshot.Profile? = nil,
        profileName: String? = nil,
        profileAge: Int? = nil,
        elapsed: WidgetSnapshot.Elapsed? = nil,
        milestones: WidgetSnapshot.Milestones? = nil,
        highlights: WidgetSnapshot.Highlights? = nil,
        daily: WidgetSnapshot.DailySummary? = nil,
        pulse: WidgetSnapshot.Pulse? = nil,
        pulseRecentEntries: [WidgetSnapshot.Pulse.JournalEntry]? = nil
    ) {
        self.updatedAt = updatedAt
        self.requestTimelineReload = requestTimelineReload
        self.profile = profile
        self.profileName = profileName
        self.profileAge = profileAge
        self.elapsed = elapsed
        self.milestones = milestones
        self.highlights = highlights
        self.daily = daily
        self.pulse = pulse
        self.pulseRecentEntries = pulseRecentEntries
    }
}

actor WidgetSnapshotSyncCoordinator {
    static let shared = WidgetSnapshotSyncCoordinator()

    private struct PendingPatch {
        var updatedAt: Date
        var requestTimelineReload: Bool
        var profile: WidgetSnapshot.Profile?
        var profileName: String?
        var profileAge: Int?
        var elapsed: WidgetSnapshot.Elapsed?
        var milestones: WidgetSnapshot.Milestones?
        var highlights: WidgetSnapshot.Highlights?
        var daily: WidgetSnapshot.DailySummary?
        var pulse: WidgetSnapshot.Pulse?
        var pulseRecentEntries: [WidgetSnapshot.Pulse.JournalEntry]?

        init(from patch: WidgetSnapshotPatch) {
            updatedAt = patch.updatedAt
            requestTimelineReload = patch.requestTimelineReload
            profile = patch.profile
            profileName = patch.profileName
            profileAge = patch.profileAge
            elapsed = patch.elapsed
            milestones = patch.milestones
            highlights = patch.highlights
            daily = patch.daily
            pulse = patch.pulse
            pulseRecentEntries = patch.pulseRecentEntries
        }

        mutating func merge(_ patch: WidgetSnapshotPatch) {
            if patch.updatedAt > updatedAt {
                updatedAt = patch.updatedAt
            }
            requestTimelineReload = requestTimelineReload || patch.requestTimelineReload
            if let value = patch.profile {
                profile = value
            }
            if let value = patch.profileName {
                profileName = value
            }
            if let value = patch.profileAge {
                profileAge = value
            }
            if let value = patch.elapsed {
                elapsed = value
            }
            if let value = patch.milestones {
                milestones = value
            }
            if let value = patch.highlights {
                highlights = value
            }
            if let value = patch.daily {
                daily = value
            }
            if let value = patch.pulse {
                pulse = value
            }
            if let value = patch.pulseRecentEntries {
                pulseRecentEntries = value
            }
        }
    }

    private let store: WidgetSnapshotStore
    private let debounceNanoseconds: UInt64
    private var pendingPatch: PendingPatch?
    private var flushTask: Task<Void, Never>?

    init(store: WidgetSnapshotStore = WidgetSnapshotStore(), debounceInterval: TimeInterval = 0.45) {
        self.store = store
        let clamped = max(0, debounceInterval)
        debounceNanoseconds = UInt64(clamped * 1_000_000_000)
    }

    func enqueue(_ patch: WidgetSnapshotPatch, immediate: Bool = false) async {
        if var pendingPatch {
            pendingPatch.merge(patch)
            self.pendingPatch = pendingPatch
        } else {
            pendingPatch = PendingPatch(from: patch)
        }

        if immediate {
            flushTask?.cancel()
            flushTask = nil
            await flushPending()
            return
        }

        scheduleFlushIfNeeded()
    }

    func enqueueHomeSnapshot(
        updatedAt: Date,
        profile: WidgetSnapshot.Profile,
        elapsed: WidgetSnapshot.Elapsed,
        milestones: WidgetSnapshot.Milestones,
        highlights: WidgetSnapshot.Highlights,
        daily: WidgetSnapshot.DailySummary,
        requestTimelineReload: Bool
    ) async {
        await enqueue(
            WidgetSnapshotPatch(
                updatedAt: updatedAt,
                requestTimelineReload: requestTimelineReload,
                profile: profile,
                elapsed: elapsed,
                milestones: milestones,
                highlights: highlights,
                daily: daily
            )
        )
    }

    func enqueuePulseSnapshot(updatedAt: Date, pulse: WidgetSnapshot.Pulse, requestTimelineReload: Bool) async {
        await enqueue(
            WidgetSnapshotPatch(
                updatedAt: updatedAt,
                requestTimelineReload: requestTimelineReload,
                pulse: pulse
            )
        )
    }

    func enqueueProfileNameAge(updatedAt: Date, name: String, age: Int, requestTimelineReload: Bool = true) async {
        await enqueue(
            WidgetSnapshotPatch(
                updatedAt: updatedAt,
                requestTimelineReload: requestTimelineReload,
                profileName: name,
                profileAge: age
            )
        )
    }

    func enqueuePulseRecentEntries(
        updatedAt: Date,
        recentEntries: [WidgetSnapshot.Pulse.JournalEntry],
        requestTimelineReload: Bool = true,
        immediate: Bool = false
    ) async {
        await enqueue(
            WidgetSnapshotPatch(
                updatedAt: updatedAt,
                requestTimelineReload: requestTimelineReload,
                pulseRecentEntries: recentEntries
            ),
            immediate: immediate
        )
    }

    func flushNow() async {
        flushTask?.cancel()
        flushTask = nil
        await flushPending()
    }

    private func scheduleFlushIfNeeded() {
        guard flushTask == nil else { return }
        let delay = debounceNanoseconds
        flushTask = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            await self.flushPending()
        }
    }

    private func flushPending() async {
        guard let pendingPatch else {
            flushTask = nil
            return
        }
        self.pendingPatch = nil
        flushTask = nil

        let requestTimelineReload = pendingPatch.requestTimelineReload

        await store.updateSnapshotAsync(requestTimelineReload: requestTimelineReload) { current in
            let hasProfileUpdate = pendingPatch.profile != nil || pendingPatch.profileName != nil || pendingPatch.profileAge != nil
            let hasPulseUpdate = pendingPatch.pulse != nil || pendingPatch.pulseRecentEntries != nil

            let baseProfile = pendingPatch.profile ?? current.profile
            let resolvedProfile = WidgetSnapshot.Profile(
                name: pendingPatch.profileName ?? baseProfile.name,
                age: pendingPatch.profileAge ?? baseProfile.age,
                monthsLeft: baseProfile.monthsLeft,
                weeksLeft: baseProfile.weeksLeft,
                daysLeft: baseProfile.daysLeft
            )

            let basePulse = pendingPatch.pulse ?? current.pulse
            let resolvedPulse = WidgetSnapshot.Pulse(
                todaySeries: basePulse.todaySeries,
                todayMax: basePulse.todayMax,
                currentFraction: basePulse.currentFraction,
                weeklyDays: basePulse.weeklyDays,
                weeklyPatternText: basePulse.weeklyPatternText,
                weeklyPeakText: basePulse.weeklyPeakText,
                weeklyLowText: basePulse.weeklyLowText,
                prescriptions: basePulse.prescriptions,
                journalPrompt: basePulse.journalPrompt,
                recentEntries: pendingPatch.pulseRecentEntries ?? basePulse.recentEntries
            )

            return WidgetSnapshot(
                syncVersion: current.syncVersion + 1,
                updatedAt: max(current.updatedAt, pendingPatch.updatedAt),
                profile: hasProfileUpdate ? resolvedProfile : current.profile,
                elapsed: pendingPatch.elapsed ?? current.elapsed,
                milestones: pendingPatch.milestones ?? current.milestones,
                highlights: pendingPatch.highlights ?? current.highlights,
                daily: pendingPatch.daily ?? current.daily,
                pulse: hasPulseUpdate ? resolvedPulse : current.pulse
            )
        }

        if self.pendingPatch != nil {
            scheduleFlushIfNeeded()
        }
    }
}
