import SwiftUI
import FamilyControls

struct SettingsView: View {
    @State private var doomSelection = BlockController.doomSelection
    @State private var goodSelection = BlockController.goodSelection
    @State private var showDoomPicker = false
    @State private var showGoodPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Doom apps — blocked unless paid for") {
                    Button("Choose apps to block…") { showDoomPicker = true }
                    Text("\(doomSelection.applicationTokens.count) apps, \(doomSelection.categoryTokens.count) categories selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Re-apply block now") { BlockController.shieldDoomApps() }
                }
                Section("Good apps — earn \(SharedConfig.goodAppChunkMinutes) min per \(SharedConfig.goodAppChunkMinutes) min used (max \(SharedConfig.maxGoodAppEarnPerDay)/day)") {
                    Button("Choose good apps…") { showGoodPicker = true }
                    Text("\(goodSelection.applicationTokens.count) apps, \(goodSelection.categoryTokens.count) categories selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Economy") {
                    LabeledContent("Exchange rate", value: "\(SharedConfig.spendRatio):1")
                    LabeledContent("Steps", value: "\(Int(SharedConfig.minutesPer1000Steps)) min / 1000")
                    LabeledContent("Good-app daily cap", value: "\(SharedConfig.maxGoodAppEarnPerDay) min")
                }
            }
            .navigationTitle("Settings")
            .familyActivityPicker(isPresented: $showDoomPicker, selection: $doomSelection)
            .familyActivityPicker(isPresented: $showGoodPicker, selection: $goodSelection)
            .onChange(of: showDoomPicker) { presented in
                if !presented {
                    BlockController.doomSelection = doomSelection
                    BlockController.shieldDoomApps()
                }
            }
            .onChange(of: showGoodPicker) { presented in
                if !presented {
                    BlockController.goodSelection = goodSelection
                    BlockController.startGoodAppMonitoring()
                }
            }
        }
    }
}
