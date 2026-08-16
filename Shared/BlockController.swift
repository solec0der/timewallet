import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

extension DeviceActivityName {
    static let spendSession = Self("spendSession")
    static let goodApps = Self("goodApps")
}

extension DeviceActivityEvent.Name {
    static let spendExpired = Self("spendExpired")
}

enum BlockController {
    static let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("timewallet"))

    private static let doomKey = "selection.doom"
    private static let goodKey = "selection.good"

    static var doomSelection: FamilyActivitySelection {
        get { load(doomKey) }
        set { save(newValue, key: doomKey) }
    }

    static var goodSelection: FamilyActivitySelection {
        get { load(goodKey) }
        set { save(newValue, key: goodKey) }
    }

    private static func load(_ key: String) -> FamilyActivitySelection {
        guard let data = SharedConfig.store.data(forKey: key),
              let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return sel
    }

    private static func save(_ sel: FamilyActivitySelection, key: String) {
        if let data = try? JSONEncoder().encode(sel) {
            SharedConfig.store.set(data, forKey: key)
        }
    }

    static func shieldDoomApps() {
        let sel = doomSelection
        store.shield.applications = sel.applicationTokens.isEmpty ? nil : sel.applicationTokens
        store.shield.applicationCategories = sel.categoryTokens.isEmpty ? nil : .specific(sel.categoryTokens)
    }

    static func unshield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    /// Buys `scrollMinutes` of doom-app usage. The purchased minutes are metered by actual
    /// usage (DeviceActivity threshold), valid until midnight; the shield returns when they
    /// are used up. Returns false when broke or when the session could not be scheduled
    /// (e.g. within 15 min of midnight — DeviceActivity's minimum interval).
    @discardableResult
    static func startSpendSession(scrollMinutes: Int) -> Bool {
        guard Wallet.spendForScroll(minutes: scrollMinutes) else { return false }

        let sel = doomSelection
        let center = DeviceActivityCenter()
        center.stopMonitoring([.spendSession])

        let now = Date()
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: false
        )
        let event = DeviceActivityEvent(
            applications: sel.applicationTokens,
            categories: sel.categoryTokens,
            webDomains: [],
            threshold: DateComponents(minute: scrollMinutes)
        )
        do {
            try center.startMonitoring(.spendSession, during: schedule, events: [.spendExpired: event])
            Stats.bump(Stats.sessionsKey)
        } catch {
            Wallet.refund(Double(scrollMinutes * SharedConfig.spendRatio),
                          reason: "Refund: session failed to start")
            shieldDoomApps()
            return false
        }
        unshield()
        SpendSession.begin(minutes: scrollMinutes)
        return true
    }

    /// Ends the current unlock immediately — re-shields, no refund (usage can't be measured).
    static func endSessionNow() {
        DeviceActivityCenter().stopMonitoring([.spendSession])
        shieldDoomApps()
        SpendSession.end()
    }

    /// Daily schedule that fires an event every 5 min of good-app usage, up to the cap.
    static func startGoodAppMonitoring() {
        let sel = goodSelection
        let center = DeviceActivityCenter()
        center.stopMonitoring([.goodApps])
        guard !sel.applicationTokens.isEmpty || !sel.categoryTokens.isEmpty else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        let chunk = SharedConfig.goodAppChunkMinutes
        for minutes in stride(from: chunk, through: SharedConfig.maxGoodAppEarnPerDay, by: chunk) {
            events[DeviceActivityEvent.Name("good_\(minutes)")] = DeviceActivityEvent(
                applications: sel.applicationTokens,
                categories: sel.categoryTokens,
                webDomains: [],
                threshold: DateComponents(minute: minutes)
            )
        }
        try? center.startMonitoring(.goodApps, during: schedule, events: events)
    }
}
