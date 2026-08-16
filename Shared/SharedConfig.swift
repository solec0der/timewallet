import Foundation

enum SharedConfig {
    static let appGroup = "group.com.solecoder.timewallet"
    static let store = UserDefaults(suiteName: appGroup) ?? .standard

    /// Earned minutes needed to buy 1 minute of scrolling (2:1 economy).
    static let spendRatio = 2

    /// Health conversion: earned minutes per 1000 steps.
    static let minutesPer1000Steps = 5.0

    /// Good-app usage credits in chunks of this many minutes…
    static let goodAppChunkMinutes = 5
    /// …up to this daily cap.
    static let maxGoodAppEarnPerDay = 60
}
