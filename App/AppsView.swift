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
                VStack(alignment: .leading, spacing: 0) {
                    Text("Blocked Apps")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 20)

                    SectionCaption(text: "Stats")
                        .padding(.bottom, Theme.headerToCardGap)
                    HStack(spacing: 10) {
                        StatCard(
                            value: "\(Stats.count(Stats.shieldShownKey))x",
                            label: "Total Prevention",
                            icon: "hand.raised.fill",
                            colors: [.orange, Color(red: 0.9, green: 0.4, blue: 0.2)]
                        )
                        StatCard(
                            value: "\(Stats.count(Stats.sessionsKey))x",
                            label: "Doom Scroll Killer",
                            icon: "bolt.shield.fill",
                            colors: [Color(red: 0.5, green: 0.3, blue: 0.9), .blue]
                        )
                        StatCard(
                            value: hoursEarned,
                            label: "Hours earned",
                            icon: "clock.fill",
                            colors: [.green, .teal]
                        )
                    }

                    SectionCaption(text: "Blocked apps")
                        .padding(.top, Theme.sectionGap)
                        .padding(.bottom, Theme.headerToCardGap)
                    selectionCard(
                        selection: doom,
                        emptyText: "No apps blocked yet.",
                        buttonTitle: "Block Multiple Apps",
                        note: "These apps are blocked. Redeem earned minutes in Focus to unlock them temporarily.",
                        action: { showDoomPicker = true }
                    )

                    SectionCaption(text: "Learn apps")
                        .padding(.top, Theme.sectionGap)
                        .padding(.bottom, Theme.headerToCardGap)
                    selectionCard(
                        selection: good,
                        emptyText: "No learn apps yet.",
                        buttonTitle: "Choose Learn Apps",
                        note: "Time in these apps earns \(SharedConfig.goodAppChunkMinutes) min per \(SharedConfig.goodAppChunkMinutes) min used, up to \(SharedConfig.maxGoodAppEarnPerDay) min per day.",
                        action: { showGoodPicker = true }
                    )
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
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
        VStack(spacing: 12) {
            Group {
                if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(selection.applicationTokens), id: \.self) { token in
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(1.4)
                                    .frame(width: 36, height: 36)
                            }
                            ForEach(Array(selection.categoryTokens), id: \.self) { token in
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(1.4)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: Theme.tileRadius).fill(Theme.tile))

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(SubtleButtonStyle())

            Text(note)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .frame(width: 38, height: 38)
                .background(Circle().fill(.white.opacity(0.22)))
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottomTrailing))
        )
    }
}
