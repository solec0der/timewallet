import Foundation
import DeviceActivity

class MonitorExtension: DeviceActivityMonitor {
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        if activity == .spendSession, event == .spendExpired {
            BlockController.shieldDoomApps()
        } else if activity == .goodApps, event.rawValue.hasPrefix("good_") {
            Wallet.earn(Double(SharedConfig.goodAppChunkMinutes), reason: "Good-app time")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity == .spendSession {
            BlockController.shieldDoomApps()
        }
    }
}
