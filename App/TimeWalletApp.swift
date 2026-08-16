import SwiftUI
import FamilyControls

@main
struct TimeWalletApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } catch {
                        print("Screen Time authorization failed: \(error)")
                    }
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            WalletView()
                .tabItem { Label("Wallet", systemImage: "creditcard") }
            EarnView()
                .tabItem { Label("Earn", systemImage: "plus.circle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
