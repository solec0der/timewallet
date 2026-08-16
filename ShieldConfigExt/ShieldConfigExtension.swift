import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigExtension: ShieldConfigurationDataSource {
    private func makeConfig() -> ShieldConfiguration {
        Stats.bump(Stats.shieldShownKey)
        let balance = Int(Wallet.balanceMinutes)
        let scroll = balance / SharedConfig.spendRatio
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: nil,
            icon: nil,
            title: ShieldConfiguration.Label(text: "⏳ Time Wallet", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "Balance: \(balance) earned min ≈ \(scroll) scroll min.\nOpen TimeWallet to buy time.",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig()
    }
}
