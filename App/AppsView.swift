import SwiftUI
import FamilyControls

struct AppsView: View {
    @State private var doom = BlockController.doomSelection
    @State private var good = BlockController.goodSelection
    @State private var showDoomPicker = false
    @State private var showGoodPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Blocked Apps")
                        .font(.largeTitle.bold())

                    Text("STATS")
                        .font(.footnote.weight(.semibold))
                        .kerning(2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(Stats.count(Stats.shieldShownKey))x",
                            label: "Total Prevention",
                            icon: "hand.raised.fill",
                            colors: [.orange, Color(red: 0.95, green: 0.45, blue: 0.2)]
                        )
                        StatCard(
                            value: "\(Stats.count(Stats.sessionsKey))x",
                            label: "Doom Scroll Killer",
                            icon: "bolt.shield.fill",
                            colors: [.purple, .blue]
                        )
                        StatCard(
                            value: hoursEarned,
                            label: "Hours earned",
                            icon: "clock.fill",
                            colors: [.green, .teal]
                        )
                    }

                    Text("BLOCKED APPS")
                        .font(.footnote.weight(.semibold))
                        .kerning(2)
                        .foregroundStyle(.secondary)

                    selectionCard(
                        selection: doom,
                        emptyText: "No apps blocked yet.",
                        buttonTitle: "Block Multiple Apps",
                        note: "These apps are blocked. Redeem earned minutes in Focus to unlock them temporarily.",
                        action: { showDoomPicker = true }
                    )

                    Text("LEARN APPS · EARN \(SharedConfig.goodAppChunkMinutes) MIN PER \(SharedConfig.goodAppChunkMinutes) MIN")
                        .font(.footnote.weight(.semibold))
                        .kerning(1)
                        .foregroundStyle(.secondary)

                    selectionCard(
                        selection: good,
                        emptyText: "No learn apps yet.",
                        buttonTitle: "Choose Learn Apps",
                        note: "Time spent in these apps earns credit automatically (max \(SharedConfig.maxGoodAppEarnPerDay) min/day).",
                        action: { showGoodPicker = true }
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .familyActivityPicker(isPresented: $showDoomPicker, selection: $doom)
            .familyActivityPicker(isPresented: $showGoodPicker, selection: $good)
            .onChange(of: showDoomPicker) { presented in
                if !presented {
                    BlockController.doomSelection = doom
                    BlockController.shieldDoomApps()
                }
            }
            .onChange(of: showGoodPicker) { presented in
                if !presented {
                    BlockController.goodSelection = good
                    BlockController.startGoodAppMonitoring()
                }
            }
        }
    }

    private var hoursEarned: String {
        let hours = Stats.totalEarned / 60
        return hours < 10 ? String(format: "%.1f", hours) : String(Int(hours))
    }

    private func selectionCard(
        selection: FamilyActivitySelection,
        emptyText: String,
        buttonTitle: String,
        note: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 14) {
            Group {
                if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                    Text(emptyText)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(selection.applicationTokens), id: \.self) { token in
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(1.6)
                                    .frame(width: 44, height: 44)
                            }
                            ForEach(Array(selection.categoryTokens), id: \.self) { token in
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(1.6)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.11)))

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.2)))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Text(note)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.11)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(white: 0.07)))
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 46, height: 46)
                .background(Circle().fill(.white.opacity(0.25)))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottomTrailing))
        )
    }
}
