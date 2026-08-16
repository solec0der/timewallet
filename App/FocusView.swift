import SwiftUI

enum FocusTimer {
    private static let startKey = "focus.start"
    private static let goalKey = "focus.goal"

    static var start: Date? {
        get {
            let t = SharedConfig.store.double(forKey: startKey)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set { SharedConfig.store.set(newValue?.timeIntervalSince1970 ?? 0, forKey: startKey) }
    }

    static var goalName: String {
        get { SharedConfig.store.string(forKey: goalKey) ?? "Focus" }
        set { SharedConfig.store.set(newValue, forKey: goalKey) }
    }
}

struct FocusGoal: Identifiable {
    var id: String { name }
    let emoji: String
    let name: String
    let targetMinutes: Int
}

struct Chore: Codable, Identifiable {
    var id = UUID()
    var name: String
    var bounty: Int
    var lastDoneDay: String?
}

enum ChoreStore {
    private static let key = "chores.list"

    static func load() -> [Chore] {
        guard let data = SharedConfig.store.data(forKey: key),
              let chores = try? JSONDecoder().decode([Chore].self, from: data) else {
            return [
                Chore(name: "Workout", bounty: 30),
                Chore(name: "Dishes / tidy up", bounty: 10),
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

struct FocusView: View {
    @State private var balance: Double = 0
    @State private var ledger: [LedgerEntry] = []
    @State private var streak = 0
    @State private var chores: [Chore] = ChoreStore.load()
    @State private var focusStart: Date? = FocusTimer.start
    @State private var now = Date()
    @State private var showRedeem = false
    @State private var message: String?
    @State private var showMessage = false
    @StateObject private var health = HealthEarn.shared

    private let goals = [
        FocusGoal(emoji: "🧘", name: "Meditation", targetMinutes: 15),
        FocusGoal(emoji: "🎯", name: "Reading", targetMinutes: 30),
    ]
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    WalletCard(balanceMinutes: balance)
                    actionButtons
                    if let start = focusStart {
                        runningSession(start: start)
                    }
                    sectionTitle("Daily Goals", icon: "flag")
                    goalsCard
                    sectionTitle("Activities", icon: "clock")
                    activitiesCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .onAppear { reload() }
            .onReceive(tick) { now = $0 }
            .refreshable { reload() }
            .sheet(isPresented: $showRedeem) { redeemSheet }
            .alert("Time Wallet", isPresented: $showMessage) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Focus")
                .font(.largeTitle.bold())
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                Text("\(streak)")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(white: 0.12)))
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showRedeem = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.orange)
                    Text("Redeem")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.6)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Running focus session

    private func runningSession(start: Date) -> some View {
        VStack(spacing: 10) {
            Text(FocusTimer.goalName)
                .font(.headline)
            Text(elapsedString(since: start))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
            Button {
                stopFocus()
            } label: {
                Text("Stop & collect")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.09)))
    }

    // MARK: - Daily goals

    private var goalsCard: some View {
        VStack(spacing: 0) {
            ForEach(goals) { goal in
                goalRow(goal)
                Divider().overlay(Color(white: 0.2))
            }
            stepsRow
            Divider().overlay(Color(white: 0.2))
            learnAppsRow
            ForEach(chores) { chore in
                Divider().overlay(Color(white: 0.2))
                choreRow(chore)
            }
        }
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.08)))
    }

    private func goalRow(_ goal: FocusGoal) -> some View {
        HStack(spacing: 14) {
            emojiTile(goal.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name).font(.headline)
                Text("\(goal.targetMinutes) min daily goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                startFocus(named: goal.name)
            } label: {
                Image(systemName: "play.fill")
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.25)))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .disabled(focusStart != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var stepsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                emojiTile("👟")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps").font(.headline)
                    Text("\(Int(health.todaySteps).formatted()) / \(Int(health.stepsGoal).formatted()) Steps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(min(100, health.todaySteps / health.stepsGoal * 100)))%")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(1, health.todaySteps / health.stepsGoal))
                .tint(.blue)
            HStack {
                Label("\(Int(health.creditedSteps).formatted()) collected", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
                Spacer()
            }
            if health.pendingSteps >= 1 {
                Button {
                    Task { await health.refresh(); health.collectSteps(); reload() }
                } label: {
                    Label("Collect \(Int(health.pendingSteps).formatted()) steps", systemImage: "square.and.arrow.down")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.2)))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var learnAppsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                emojiTile("📚")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Learn Apps").font(.headline)
                    Text("\(Stats.goodToday(day: DayKey.today())) / \(SharedConfig.maxGoodAppEarnPerDay) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            ProgressView(value: min(1, Double(Stats.goodToday(day: DayKey.today())) / Double(SharedConfig.maxGoodAppEarnPerDay)))
                .tint(.blue)
            Text("Time in your chosen learn apps auto-credits every \(SharedConfig.goodAppChunkMinutes) min.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func choreRow(_ chore: Chore) -> some View {
        let done = chore.lastDoneDay == DayKey.today()
        return HStack(spacing: 14) {
            emojiTile("✅")
            VStack(alignment: .leading, spacing: 2) {
                Text(chore.name).font(.headline)
                Text("+\(chore.bounty) min bounty · once per day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                complete(chore)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(done)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Activities

    private var activitiesCard: some View {
        VStack(spacing: 0) {
            if ledger.isEmpty {
                Text("Nothing yet. Go earn some time.")
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            ForEach(Array(ledger.prefix(25).enumerated()), id: \.element.id) { index, entry in
                if index > 0 { Divider().overlay(Color(white: 0.2)) }
                activityRow(entry)
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.08)))
    }

    private func activityRow(_ entry: LedgerEntry) -> some View {
        HStack(spacing: 14) {
            emojiTile(icon(for: entry))
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: entry)).font(.headline)
                Text(entry.date, format: .relative(presentation: .named))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountString(entry.minutes))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(entry.minutes >= 0 ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func icon(for entry: LedgerEntry) -> String {
        if entry.minutes < 0 { return "💀" }
        let r = entry.reason.lowercased()
        if r.contains("step") { return "👟" }
        if r.contains("exercise") || r.contains("workout") { return "💪" }
        if r.contains("meditation") { return "🧘" }
        if r.contains("reading") { return "🎯" }
        if r.contains("learn") { return "📚" }
        if r.contains("task") { return "✅" }
        return "⏳"
    }

    private func title(for entry: LedgerEntry) -> String {
        entry.minutes < 0 ? "Social Media Session" : entry.reason
    }

    private func amountString(_ minutes: Double) -> String {
        let value = minutes == minutes.rounded()
            ? String(Int(minutes))
            : String(format: "%.1f", minutes)
        return (minutes > 0 ? "+" : "") + value + " min"
    }

    // MARK: - Redeem sheet

    private var redeemSheet: some View {
        NavigationStack {
            List {
                Section("Unlock scroll time · rate \(SharedConfig.spendRatio):1") {
                    ForEach([5, 10, 15, 30], id: \.self) { minutes in
                        Button {
                            showRedeem = false
                            spend(minutes)
                        } label: {
                            HStack {
                                Text("Unlock \(minutes) min")
                                Spacer()
                                Text("−\(minutes * SharedConfig.spendRatio) min")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(balance < Double(minutes * SharedConfig.spendRatio))
                    }
                }
                Section {
                    Text("Unlocked minutes are metered by actual usage and stay valid until midnight.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Redeem")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.12)))
            Text(title).font(.title2.bold())
        }
    }

    private func emojiTile(_ emoji: String) -> some View {
        Text(emoji)
            .font(.title2)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.14)))
    }

    private func reload() {
        balance = Wallet.balanceMinutes
        ledger = Wallet.ledger()
        chores = ChoreStore.load()
        streak = computeStreak()
        Task { await health.refresh() }
    }

    private func computeStreak() -> Int {
        let earnDays = Set(ledger.filter { $0.minutes > 0 }.map { DayKey.today($0.date) })
        var streak = 0
        var day = Date()
        // Today counts if something was earned; otherwise start checking yesterday.
        if !earnDays.contains(DayKey.today(day)) {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while earnDays.contains(DayKey.today(day)) {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    private func startFocus(named name: String) {
        FocusTimer.goalName = name
        FocusTimer.start = Date()
        focusStart = FocusTimer.start
    }

    private func stopFocus() {
        guard let start = focusStart else { return }
        let minutes = floor(Date().timeIntervalSince(start) / 60)
        if minutes >= 1 {
            Wallet.earn(minutes, reason: FocusTimer.goalName)
        }
        FocusTimer.start = nil
        focusStart = nil
        reload()
    }

    private func complete(_ chore: Chore) {
        guard let idx = chores.firstIndex(where: { $0.id == chore.id }) else { return }
        chores[idx].lastDoneDay = DayKey.today()
        ChoreStore.save(chores)
        Wallet.earn(Double(chore.bounty), reason: "Task: \(chore.name)")
        reload()
    }

    private func spend(_ minutes: Int) {
        if BlockController.startSpendSession(scrollMinutes: minutes) {
            message = "Unlocked \(minutes) min of usage. The shield returns when they're used up (or at midnight)."
        } else if Wallet.balanceMinutes < Double(minutes * SharedConfig.spendRatio) {
            message = "Not enough balance — you need \(minutes * SharedConfig.spendRatio) earned minutes."
        } else {
            message = "Couldn't start the session (too close to midnight?). You were refunded."
        }
        showMessage = true
        reload()
    }

    private func elapsedString(since start: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

// MARK: - Wallet card

struct WalletCard: View {
    let balanceMinutes: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Time Wallet")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
            HStack(alignment: .bottom) {
                chip
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("BALANCE")
                        .font(.caption2)
                        .kerning(2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(Int(balanceMinutes))min")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            Text("* * * *   3846")
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("CARD HOLDER")
                    .font(.caption2)
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.6))
                Text("YANNICK")
                    .font(.callout.weight(.semibold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.78), Color(white: 0.55), Color(white: 0.38)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .white.opacity(0.08), radius: 20)
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(colors: [Color(red: 0.9, green: 0.75, blue: 0.35),
                                        Color(red: 0.72, green: 0.55, blue: 0.2)],
                               startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 52, height: 40)
            .overlay(
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow { chipCell; chipCell; chipCell }
                    GridRow { chipCell; chipCell; chipCell }
                }
            )
    }

    private var chipCell: some View {
        Rectangle()
            .stroke(Color.black.opacity(0.25), lineWidth: 0.8)
            .frame(width: 17, height: 20)
    }
}
