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
                VStack(alignment: .leading, spacing: 0) {
                    pillsRow
                        .padding(.bottom, 16)
                    WalletCard(balanceMinutes: balance, holder: SharedConfig.cardHolder)
                        .padding(.bottom, 14)
                    if let session = activeSession {
                        ActiveSessionCard(session: session, now: now) {
                            BlockController.endSessionNow()
                            reload()
                        }
                    } else {
                        redeemButton
                    }
                    if let start = focusStart {
                        runningSession(start: start)
                            .padding(.top, Theme.sectionGap)
                    }

                    SectionHeader(title: "Daily Goals", icon: "flag")
                        .padding(.top, Theme.sectionGap)
                        .padding(.bottom, Theme.headerToCardGap)
                    goalsCard

                    SectionHeader(title: "Activities", icon: "clock")
                        .padding(.top, Theme.sectionGap)
                        .padding(.bottom, Theme.headerToCardGap)
                    activitiesCard
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .onAppear { reload() }
            .onReceive(tick) { now = $0 }
            .refreshable { reload() }
            .sheet(isPresented: $showRedeem) {
                RedeemSheet(balance: balance) { minutes in
                    spend(minutes)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationRouter.openRedeem)) { _ in
                reload()
                showRedeem = true
            }
            .alert("Time Wallet", isPresented: $showMessage) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    private var activeSession: SpendSession.Record? {
        guard let session = SpendSession.current, session.active else { return nil }
        return session
    }

    // MARK: - Top pills

    private var pillsRow: some View {
        HStack(spacing: 8) {
            pill {
                Label("\(Int(Stats.totalEarned)) min", systemImage: "trophy")
            }
            Spacer()
            pill {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(streak > 0 ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                    Text("\(streak)")
                }
            }
        }
    }

    private func pill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(Theme.card))
    }

    // MARK: - Redeem

    private var redeemButton: some View {
        Button {
            showRedeem = true
        } label: {
            Label("Redeem", systemImage: "arrow.up.circle.fill")
        }
        .buttonStyle(SubtleButtonStyle())
    }

    // MARK: - Running focus session

    private func runningSession(start: Date) -> some View {
        VStack(spacing: 12) {
            Text(FocusTimer.goalName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(elapsedString(since: start))
                .font(.system(size: 36, weight: .semibold, design: .monospaced))
                .monospacedDigit()
            Button("Stop & collect") {
                stopFocus()
            }
            .buttonStyle(SubtleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
    }

    // MARK: - Daily goals

    private var goalsCard: some View {
        CardGroup {
            ForEach(goals) { goal in
                goalRow(goal)
                InsetDivider()
            }
            stepsRow
            InsetDivider()
            learnAppsRow
            ForEach(chores) { chore in
                InsetDivider()
                choreRow(chore)
            }
        }
    }

    private func goalRow(_ goal: FocusGoal) -> some View {
        HStack(spacing: 12) {
            EmojiTile(emoji: goal.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .font(.body.weight(.medium))
                Text("\(goal.targetMinutes) min daily goal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                startFocus(named: goal.name)
            } label: {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Color.blue.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .disabled(focusStart != nil)
            .opacity(focusStart != nil ? 0.4 : 1)
        }
        .padding(.horizontal, Theme.rowPaddingH)
        .padding(.vertical, Theme.rowPaddingV)
    }

    private var stepsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                EmojiTile(emoji: "👟")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps")
                        .font(.body.weight(.medium))
                    Text("\(Int(health.todaySteps).formatted()) / \(Int(health.stepsGoal).formatted()) steps")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(min(100, health.todaySteps / health.stepsGoal * 100)))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(1, health.todaySteps / health.stepsGoal))
                .tint(.blue)
            Label("\(Int(health.creditedSteps).formatted()) collected", systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.green)
            if health.pendingSteps >= 1 {
                Button {
                    Task { await health.refresh(); health.collectSteps(); reload() }
                } label: {
                    Label("Collect \(Int(health.pendingSteps).formatted()) steps", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SubtleButtonStyle())
            }
        }
        .padding(.horizontal, Theme.rowPaddingH)
        .padding(.vertical, Theme.rowPaddingV)
    }

    private var learnAppsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                EmojiTile(emoji: "📚")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Learn Apps")
                        .font(.body.weight(.medium))
                    Text("\(Stats.goodToday(day: DayKey.today())) / \(SharedConfig.maxGoodAppEarnPerDay) min · auto-credits")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            ProgressView(value: min(1, Double(Stats.goodToday(day: DayKey.today())) / Double(SharedConfig.maxGoodAppEarnPerDay)))
                .tint(.blue)
        }
        .padding(.horizontal, Theme.rowPaddingH)
        .padding(.vertical, Theme.rowPaddingV)
    }

    private func choreRow(_ chore: Chore) -> some View {
        let done = chore.lastDoneDay == DayKey.today()
        return HStack(spacing: 12) {
            EmojiTile(emoji: "🧹")
            VStack(alignment: .leading, spacing: 2) {
                Text(chore.name)
                    .font(.body.weight(.medium))
                Text("+\(chore.bounty) min · once per day")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                complete(chore)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(done)
        }
        .padding(.horizontal, Theme.rowPaddingH)
        .padding(.vertical, Theme.rowPaddingV)
    }

    // MARK: - Activities

    private var activitiesCard: some View {
        CardGroup {
            if ledger.isEmpty {
                Text("Nothing yet. Go earn some time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(18)
            }
            ForEach(Array(ledger.prefix(25).enumerated()), id: \.element.id) { index, entry in
                if index > 0 { InsetDivider() }
                activityRow(entry)
            }
        }
    }

    private func activityRow(_ entry: LedgerEntry) -> some View {
        HStack(spacing: 12) {
            EmojiTile(emoji: icon(for: entry))
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: entry))
                    .font(.body.weight(.medium))
                Text(entry.date, format: .relative(presentation: .named))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountString(entry.minutes))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(entry.minutes >= 0 ? .green : .red)
        }
        .padding(.horizontal, Theme.rowPaddingH)
        .padding(.vertical, Theme.rowPaddingV)
    }

    private func icon(for entry: LedgerEntry) -> String {
        if entry.minutes < 0 { return "💀" }
        let r = entry.reason.lowercased()
        if r.contains("step") { return "👟" }
        if r.contains("exercise") || r.contains("workout") { return "💪" }
        if r.contains("meditation") { return "🧘" }
        if r.contains("reading") { return "🎯" }
        if r.contains("learn") { return "📚" }
        if r.contains("task") { return "🧹" }
        return "⏳" }

    private func title(for entry: LedgerEntry) -> String {
        entry.minutes < 0 ? "Social Media Session" : entry.reason
    }

    private func amountString(_ minutes: Double) -> String {
        let value = minutes == minutes.rounded()
            ? String(Int(minutes))
            : String(format: "%.1f", minutes)
        return (minutes > 0 ? "+" : "") + value + " min"
    }

    // MARK: - Actions

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
            message = "Unlocked \(minutes) min of usage. The shield returns when they're used up."
        } else if Wallet.balanceMinutes < Double(minutes * SharedConfig.spendRatio) {
            message = "Not enough balance — you need \(minutes * SharedConfig.spendRatio) earned minutes."
        } else {
            message = "Couldn't start the session — you were refunded. Try again in a moment."
        }
        showMessage = true
        reload()
    }

    private func elapsedString(since start: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

// MARK: - Active session card

struct ActiveSessionCard: View {
    let session: SpendSession.Record
    let now: Date
    let onLock: () -> Void

    @State private var pulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.white)
                    .frame(width: 9, height: 9)
                    .opacity(pulsing ? 0.25 : 1)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
                Text("DOOM SCROLL SESSION")
                    .font(.caption.weight(.bold))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(elapsed)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(session.minutes)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("min unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            Text("Metered by actual use — the shield returns after \(session.minutes) min in your blocked apps (\(Int(SharedConfig.sessionMaxHours)) h max).")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Button(action: onLock) {
                Label("Lock again now", systemImage: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: Theme.tileRadius).fill(.white.opacity(0.2)))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.25, blue: 0.3),
                                 Color(red: 0.5, green: 0.12, blue: 0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .onAppear { pulsing = true }
    }

    private var elapsed: String {
        let seconds = max(0, Int(now.timeIntervalSince(session.startedAt)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60) + " ago"
    }
}

// MARK: - Redeem sheet

struct RedeemSheet: View {
    let balance: Double
    let onRedeem: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Int?

    private let presets = [5, 10, 15, 30]
    private var ratio: Int { SharedConfig.spendRatio }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Redeem")
                    .font(.title2.weight(.bold))
                Text("Balance: \(Int(balance)) min · rate \(ratio) → 1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(presets, id: \.self) { minutes in
                    presetCard(minutes)
                }
            }

            Spacer(minLength: 0)

            Button {
                if let selected {
                    dismiss()
                    onRedeem(selected)
                }
            } label: {
                Text(selected.map { "Unlock \($0) min for \($0 * ratio) min" } ?? "Choose an amount")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected == nil)

            Text("Unlocked minutes are metered by actual usage and stay valid for \(Int(SharedConfig.sessionMaxHours)) hours.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
    }

    private func presetCard(_ minutes: Int) -> some View {
        let cost = minutes * ratio
        let affordable = balance >= Double(cost)
        let isSelected = selected == minutes
        return Button {
            selected = minutes
        } label: {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("min unlocked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("−\(cost) min")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(affordable ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Theme.tile)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .stroke(isSelected ? Color.blue : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .opacity(affordable ? 1 : 0.4)
    }
}

// MARK: - Wallet card

struct WalletCard: View {
    let balanceMinutes: Double
    let holder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Time Wallet")
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.95))
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("BALANCE")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(1.5)
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(Int(balanceMinutes))min")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            chip
            Spacer()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("✱ ✱ ✱ ✱  3846")
                        .font(.system(.subheadline, design: .monospaced).weight(.medium))
                        .kerning(2)
                        .foregroundStyle(.white.opacity(0.85))
                    if !holder.isEmpty {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CARD HOLDER")
                                .font(.system(size: 9, weight: .semibold))
                                .kerning(1.5)
                                .foregroundStyle(.white.opacity(0.55))
                            Text(holder.uppercased())
                                .font(.footnote.weight(.semibold))
                                .kerning(2)
                                .foregroundStyle(.white.opacity(0.95))
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 205)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.75), Color(white: 0.52), Color(white: 0.36)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(.white.opacity(0.18), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(
                LinearGradient(colors: [Color(red: 0.88, green: 0.74, blue: 0.38),
                                        Color(red: 0.7, green: 0.54, blue: 0.22)],
                               startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 44, height: 33)
            .overlay(
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow { chipCell; chipCell; chipCell }
                    GridRow { chipCell; chipCell; chipCell }
                }
            )
    }

    private var chipCell: some View {
        Rectangle()
            .stroke(Color.black.opacity(0.22), lineWidth: 0.7)
            .frame(width: 14.5, height: 16.5)
    }
}
