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
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
            AppsView()
                .tabItem { Label("Apps", systemImage: "nosign") }
            AdjustView()
                .tabItem { Label("Adjust", systemImage: "slider.horizontal.3") }
        }
        .preferredColorScheme(.dark)
    }
}
