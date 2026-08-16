import ManagedSettings
import UserNotifications

class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    private func respond(to action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .secondaryButtonPressed:
            postRedeemNotification()
            completionHandler(.close)
        default:
            completionHandler(.close)
        }
    }

    /// The shield can't open apps, but it can post a local notification that
    /// deep-links into TimeWallet's redeem sheet when tapped.
    private func postRedeemNotification() {
        let balance = Int(Wallet.balanceMinutes)
        let scroll = balance / SharedConfig.spendRatio
        let content = UNMutableNotificationContent()
        content.title = "⏳ Time Wallet"
        content.body = scroll > 0
            ? "You can afford \(scroll) min of scrolling (\(balance) min earned). Tap to redeem."
            : "You're broke — \(balance) min earned. Tap to see how to top up."
        content.sound = .default
        content.userInfo = ["action": "redeem"]
        let request = UNNotificationRequest(identifier: "timewallet.redeem", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
