import Foundation

/// State of the current (or last) doom-scroll unlock, shared with extensions.
enum SpendSession {
    struct Record: Codable {
        var startedAt: Date
        var minutes: Int
        var active: Bool
        var endedAt: Date?
    }

    private static let key = "session.current"

    static var current: Record? {
        get {
            guard let data = SharedConfig.store.data(forKey: key),
                  var record = try? JSONDecoder().decode(Record.self, from: data) else {
                return nil
            }
            // Sessions never survive midnight; lazily close a stale one.
            if record.active, !Calendar.current.isDateInToday(record.startedAt) {
                record.active = false
                record.endedAt = record.endedAt ?? record.startedAt
                save(record)
            }
            return record
        }
        set {
            if let newValue { save(newValue) } else { SharedConfig.store.removeObject(forKey: key) }
        }
    }

    static func begin(minutes: Int) {
        current = Record(startedAt: Date(), minutes: minutes, active: true, endedAt: nil)
    }

    static func end() {
        guard var record = current, record.active else { return }
        record.active = false
        record.endedAt = Date()
        save(record)
    }

    private static func save(_ record: Record) {
        if let data = try? JSONEncoder().encode(record) {
            SharedConfig.store.set(data, forKey: key)
        }
    }
}
