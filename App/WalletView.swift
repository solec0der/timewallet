import SwiftUI

struct WalletView: View {
    @State private var balance: Double = 0
    @State private var ledger: [LedgerEntry] = []
    @State private var message: String?
    @State private var showMessage = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 4) {
                        Text("\(Int(balance))")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                        Text("earned minutes")
                            .foregroundStyle(.secondary)
                        Text("buys \(Int(balance) / SharedConfig.spendRatio) min of scrolling")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                Section("Buy scroll time (\(SharedConfig.spendRatio):1)") {
                    ForEach([5, 10, 15], id: \.self) { minutes in
                        Button {
                            spend(minutes)
                        } label: {
                            HStack {
                                Text("Unlock \(minutes) min")
                                Spacer()
                                Text("−\(minutes * SharedConfig.spendRatio) min")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Ledger") {
                    if ledger.isEmpty {
                        Text("Nothing yet. Go earn some time.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(ledger.prefix(30)) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.reason)
                                Text(entry.date, format: .dateTime.day().month().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.minutes > 0 ? "+\(Int(entry.minutes))" : "\(Int(entry.minutes))")
                                .foregroundStyle(entry.minutes > 0 ? .green : .red)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Time Wallet")
            .refreshable { reload() }
            .onAppear { reload() }
            .alert("Wallet", isPresented: $showMessage) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    private func reload() {
        balance = Wallet.balanceMinutes
        ledger = Wallet.ledger()
    }

    private func spend(_ minutes: Int) {
        if BlockController.startSpendSession(scrollMinutes: minutes) {
            message = "Unlocked. You have \(minutes) min of actual usage — the shield comes back when they're used up (or at midnight)."
        } else if Wallet.balanceMinutes < Double(minutes * SharedConfig.spendRatio) {
            message = "Not enough balance. You need \(minutes * SharedConfig.spendRatio) earned minutes."
        } else {
            message = "Couldn't start the session (too close to midnight?). You were refunded."
        }
        showMessage = true
        reload()
    }
}
