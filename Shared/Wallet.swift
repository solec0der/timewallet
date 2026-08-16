import Foundation

struct LedgerEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var minutes: Double
    var reason: String
}

enum Wallet {
    private static let balanceKey = "wallet.balance"
    private static let ledgerKey = "wallet.ledger"

    static var balanceMinutes: Double {
        SharedConfig.store.double(forKey: balanceKey)
    }

    static func ledger() -> [LedgerEntry] {
        guard let data = SharedConfig.store.data(forKey: ledgerKey),
              let entries = try? JSONDecoder().decode([LedgerEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func earn(_ minutes: Double, reason: String) {
        guard minutes > 0 else { return }
        add(minutes, reason: reason)
    }

    /// Deducts the cost of a scroll session at the configured ratio. Returns false when broke.
    static func spendForScroll(minutes scrollMinutes: Int) -> Bool {
        let cost = Double(scrollMinutes * SharedConfig.spendRatio)
        guard balanceMinutes >= cost else { return false }
        add(-cost, reason: "\(scrollMinutes) min scroll session")
        return true
    }

    static func refund(_ minutes: Double, reason: String) {
        add(minutes, reason: reason)
    }

    private static func add(_ minutes: Double, reason: String) {
        let store = SharedConfig.store
        store.set(balanceMinutes + minutes, forKey: balanceKey)
        if minutes > 0 { Stats.addEarned(minutes) }
        var entries = ledger()
        entries.insert(LedgerEntry(date: Date(), minutes: minutes, reason: reason), at: 0)
        if entries.count > 300 { entries = Array(entries.prefix(300)) }
        if let data = try? JSONEncoder().encode(entries) {
            store.set(data, forKey: ledgerKey)
        }
    }
}
