import SwiftUI

enum FocusTimer {
    private static let key = "focus.start"
    static var start: Date? {
        get {
            let t = SharedConfig.store.double(forKey: key)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set { SharedConfig.store.set(newValue?.timeIntervalSince1970 ?? 0, forKey: key) }
    }
}

struct Chore: Codable, Identifiable {
    var id = UUID()
    var name: String
    var bounty: Int
    var lastDoneDay: String?
}

enum ChoreStore {
    private static let key = "chores.list"

    static func dayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    static func load() -> [Chore] {
        guard let data = SharedConfig.store.data(forKey: key),
              let chores = try? JSONDecoder().decode([Chore].self, from: data) else {
            return [
                Chore(name: "Workout", bounty: 30),
                Chore(name: "Dishes / tidy up", bounty: 10),
                Chore(name: "Inbox zero", bounty: 15),
            ]
        }
        return chores
    }

    static func save(_ chores: [Chore]) {
        if let data = try? JSONEncoder().encode(chores) {
            SharedConfig.store.set(data, forKey: key)
        }
    }
}

struct EarnView: View {
    @State private var focusStart: Date? = FocusTimer.start
    @State private var now = Date()
    @State private var chores: [Chore] = ChoreStore.load()
    @StateObject private var health = HealthEarn.shared
    @State private var showNewChore = false
    @State private var newChoreName = ""
    @State private var newChoreBounty = 10

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                Section("Focus timer — 1 min focus = 1 min earned") {
                    if let start = focusStart {
                        Text(elapsed(since: start))
                            .font(.system(.title, design: .monospaced))
                        Button("Stop & collect") { stopFocus() }
                    } else {
                        Button("Start focus session") {
                            FocusTimer.start = Date()
                            focusStart = FocusTimer.start
                        }
                    }
                }
                Section("Tasks — fixed bounties, once per day") {
                    ForEach(chores) { chore in
                        Button {
                            complete(chore)
                        } label: {
                            HStack {
                                Image(systemName: doneToday(chore) ? "checkmark.circle.fill" : "circle")
                                Text(chore.name)
                                Spacer()
                                Text("+\(chore.bounty) min")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(doneToday(chore))
                    }
                    .onDelete { idx in
                        chores.remove(atOffsets: idx)
                        ChoreStore.save(chores)
                    }
                    Button("Add task…") { showNewChore = true }
                }
                Section("Health — \(Int(SharedConfig.minutesPer1000Steps)) min per 1000 steps, exercise 1:1") {
                    Button("Sync steps & exercise") {
                        Task { await health.syncToday() }
                    }
                    if !health.status.isEmpty {
                        Text(health.status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Earn")
            .onReceive(tick) { now = $0 }
            .alert("New task", isPresented: $showNewChore) {
                TextField("Name", text: $newChoreName)
                Button("Add (+\(newChoreBounty) min)") {
                    guard !newChoreName.isEmpty else { return }
                    chores.append(Chore(name: newChoreName, bounty: newChoreBounty))
                    ChoreStore.save(chores)
                    newChoreName = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Bounty is 10 min by default — edit in code for now.")
            }
        }
    }

    private func doneToday(_ chore: Chore) -> Bool {
        chore.lastDoneDay == ChoreStore.dayKey()
    }

    private func complete(_ chore: Chore) {
        guard let idx = chores.firstIndex(where: { $0.id == chore.id }) else { return }
        chores[idx].lastDoneDay = ChoreStore.dayKey()
        ChoreStore.save(chores)
        Wallet.earn(Double(chore.bounty), reason: "Task: \(chore.name)")
    }

    private func elapsed(since start: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    private func stopFocus() {
        guard let start = focusStart else { return }
        let minutes = floor(Date().timeIntervalSince(start) / 60)
        if minutes >= 1 {
            Wallet.earn(minutes, reason: "Focus session")
        }
        FocusTimer.start = nil
        focusStart = nil
    }
}
