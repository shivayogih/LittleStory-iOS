import Common
import CoreUI
import Domain
import Foundation
import Observation

public struct SubscriptionState: Sendable, Hashable {
    public var plans: [Plan] = []
    public var selectedID = AppConfig.Subscription.defaultPlanID
    /// Set after "Choose"; the screen shows the prototype dialog while it is set.
    public var confirmedID: String?

    public var selected: Plan? { plans.first { $0.id == selectedID } }

    public var chooseLabel: UIText { SettingsStrings.Subscription.choose(.localized(SettingsStrings.Subscription.planName(selectedID))) }

    public var confirmedText: UIText? {
        confirmedID.map { SettingsStrings.Subscription.dialogText(.localized(SettingsStrings.Subscription.planName($0))) }
    }
}

public extension Plan {
    var name: UIText { UIText(SettingsStrings.Subscription.planName(id)) }

    /// "per month", "per year · best value", "per year · up to 4 children" or "Try the magic".
    var period: UIText {
        if priceMinorUnits == 0 {
            return UIText(SettingsStrings.Subscription.periodFree)
        }
        if maxChildren > 1 {
            return SettingsStrings.Subscription.periodFamily(.number(maxChildren))
        }
        return UIText(billedYearly ? SettingsStrings.Subscription.periodYear : SettingsStrings.Subscription.periodMonth)
    }

    /// The illustrative price in the plan's currency, whole units, for `locale`.
    func price(locale: Locale) -> String {
        let digits = Self.fractionDigits(currencyCode)
        let amount = Decimal(priceMinorUnits) / pow(Decimal(Self.decimalBase), digits)
        return amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(locale))
    }

    private static let decimalBase = 10

    /// The currency's minor-unit digits (2 for INR, 0 for JPY).
    private static func fractionDigits(_ code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.maximumFractionDigits
    }
}

/// Subscription (SCR-15): illustrative plans behind `FeatureFlags.demoSubscription`. No billing,
/// no StoreKit, nothing is charged.
@MainActor
@Observable
public final class SubscriptionViewModel {
    public private(set) var state = SubscriptionState()
    @ObservationIgnored private let subscription: any SubscriptionRepository

    public init(subscription: any SubscriptionRepository) {
        self.subscription = subscription
    }

    public func start() async {
        for await plans in subscription.plans() {
            state.plans = plans
        }
    }

    public func onSelect(_ planID: String) {
        state.selectedID = planID
    }

    public func onChoose() {
        guard state.selected != nil else {
            return
        }
        state.confirmedID = state.selectedID
    }

    public func onDialogDismissed() {
        state.confirmedID = nil
    }
}
