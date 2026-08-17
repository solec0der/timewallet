import SwiftUI
import FamilyControls

struct AdjustView: View {
    @State private var ratio = SharedConfig.spendRatio
    @State private var cardHolder = SharedConfig.cardHolder
    @State private var troubleshootDone = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker(selection: $ratio) {
                        Text("Easy · 1 → 1").tag(1)
                        Text("Normal · 2 → 1").tag(2)
                        Text("Hard · 3 → 1").tag(3)
                    } label: {
                        Label("Difficulty", systemImage: "gauge.with.needle")
                    }
                    .onChange(of: ratio) { newValue in
                        SharedConfig.spendRatio = newValue
                    }
                    HStack {
                        Label("Card holder", systemImage: "person")
                        Spacer()
                        TextField("Your name", text: $cardHolder)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .onChange(of: cardHolder) { newValue in
                                SharedConfig.cardHolder = newValue
                            }
                    }
                }

                Section("Economy") {
                    LabeledContent("Exchange rate", value: "\(ratio) earned → 1 scroll")
                    LabeledContent("Steps", value: "\(Int(SharedConfig.minutesPer1000Steps)) min / 1000")
                    LabeledContent("Learn-app daily cap", value: "\(SharedConfig.maxGoodAppEarnPerDay) min")
                }

                Section {
                    Button {
                        BlockController.shieldDoomApps()
                        BlockController.startGoodAppMonitoring()
                        troubleshootDone = true
                    } label: {
                        Label("Troubleshoot Blocking", systemImage: "wrench")
                    }
                    if troubleshootDone {
                        Label("Shield re-applied, learn-app tracking restarted.", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                    Text("Verify your setup and fix common blocking issues.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Settings")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.6")
                    LabeledContent("Plan", value: "0 CHF / week 😌")
                }
            }
            .navigationTitle("Adjust")
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
}
