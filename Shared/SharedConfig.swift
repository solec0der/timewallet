import Foundation

enum SharedConfig {
    static let appGroup = "group.com.solecoder.timewallet"
    static let store = UserDefaults(suiteName: appGroup) ?? .standard

    /// Earned minutes needed to buy 1 minute of scrolling. Adjustable via
    /// the Difficulty setting (Easy 1:1, Normal 2:1, Hard 3:1); default 2:1.
    static var spendRatio: Int {
        get {
            let stored = store.integer(forKey: "economy.spendRatio")
            return stored > 0 ? stored : 2
        }
        set { store.set(newValue, forKey: "economy.spendRatio") }
    }

    /// Health conversion: earned minutes per 1000 steps.
    static let minutesPer1000Steps = 5.0

    /// Good-app usage credits in chunks of this many minutes…
    static let goodAppChunkMinutes = 5
    /// …up to this daily cap.
    static let maxGoodAppEarnPerDay = 60
}
