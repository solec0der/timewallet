import Foundation

enum DayKey {
    static func today(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}

/// Lightweight counters shared between app and extensions.
enum Stats {
    static let shieldShownKey = "stats.shieldShown"
    static let sessionsKey = "stats.sessions"
    static let totalEarnedKey = "stats.totalEarned"

    static func bump(_ key: String) {
        SharedConfig.store.set(count(key) + 1, forKey: key)
    }

    static func count(_ key: String) -> Int {
        SharedConfig.store.integer(forKey: key)
    }

    static func addEarned(_ minutes: Double) {
        SharedConfig.store.set(totalEarned + minutes, forKey: totalEarnedKey)
    }

    static var totalEarned: Double {
        SharedConfig.store.double(forKey: totalEarnedKey)
    }

    static func goodTodayKey(_ day: String) -> String { "stats.good.\(day)" }

    static func addGoodToday(_ minutes: Int, day: String) {
        let key = goodTodayKey(day)
        SharedConfig.store.set(SharedConfig.store.integer(forKey: key) + minutes, forKey: key)
    }

    static func goodToday(day: String) -> Int {
        SharedConfig.store.integer(forKey: goodTodayKey(day))
    }
}
