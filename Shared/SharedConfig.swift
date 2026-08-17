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

    /// Name embossed on the wallet card; empty hides the card-holder line.
    static var cardHolder: String {
        get { store.string(forKey: "profile.cardHolder") ?? "" }
        set { store.set(newValue, forKey: "profile.cardHolder") }
    }

    /// A spend session ends when its minutes are used up, or after this hard cap —
    /// bounding how long apps can stay unshielded if you stop scrolling early.
    static let sessionMaxHours: Double = 3

    /// Good-app usage credits in chunks of this many minutes…
    static let goodAppChunkMinutes = 5
    /// …up to this daily cap.
    static let maxGoodAppEarnPerDay = 60
}
