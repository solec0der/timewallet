import SwiftUI
import FamilyControls
import UserNotifications

/// Routes notification taps (from the shield's "Redeem time…" button) into the app.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    static let openRedeem = Notification.Name("timewallet.openRedeem")

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["action"] as? String == "redeem" {
            NotificationCenter.default.post(name: Self.openRedeem, object: nil)
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct TimeWalletApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } catch {
                        print("Screen Time authorization failed: \(error)")
                    }
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound])
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
