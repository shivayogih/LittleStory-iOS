import Domain

/// Illustrative plans from `Mock/plans.json`. Prices are not translated text, so there is one file.
public struct SubscriptionRepositoryImpl: SubscriptionRepository {
    private let source: any MockContentSource

    public init(source: any MockContentSource) {
        self.source = source
    }

    public func plans() -> AsyncStream<[Plan]> {
        let entries = source.decode(PlansFile.self, from: MockFile.plans)?.plans ?? []
        return .of(entries.map { entry in
            Plan(
                id: entry.id,
                priceMinorUnits: entry.priceMinorUnits ?? 0,
                currencyCode: entry.currencyCode ?? "",
                billedYearly: entry.billedYearly ?? false,
                bestValue: entry.bestValue ?? false,
                maxChildren: entry.maxChildren ?? 1,
            )
        })
    }
}
