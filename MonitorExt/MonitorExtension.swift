import Foundation
import DeviceActivity

class MonitorExtension: DeviceActivityMonitor {
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        if activity == .spendSession, event == .spendExpired {
            BlockController.shieldDoomApps()
            SpendSession.end()
        } else if activity == .goodApps, event.rawValue.hasPrefix("good_") {
            let chunk = SharedConfig.goodAppChunkMinutes
            Wallet.earn(Double(chunk), reason: "Learn-app time")
            Stats.addGoodToday(chunk, day: DayKey.today())
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity == .spendSession {
            BlockController.shieldDoomApps()
            SpendSession.end()
        }
    }
}
