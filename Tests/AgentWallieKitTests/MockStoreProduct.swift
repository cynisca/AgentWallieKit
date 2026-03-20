import Foundation
@testable import AgentWallieKit

/// Mock implementation of StoreProductProviding for unit tests.
/// StoreKit.Product cannot be instantiated in tests, so this provides
/// the same interface with controllable data.
@available(iOS 16.0, *)
struct MockStoreProduct: StoreProductProviding, Sendable {
    var id: String
    var displayPrice: String
    var price: Decimal
    var subscriptionPeriodUnit: ProductResolver.PeriodUnit?
    var subscriptionPeriodValue: Int?
    var introOfferPaymentMode: ProductResolver.IntroPaymentMode?
    var introOfferPeriodUnit: ProductResolver.PeriodUnit?
    var introOfferPeriodValue: Int?
    var introOfferDisplayPrice: String?

    init(
        id: String,
        displayPrice: String,
        price: Decimal,
        subscriptionPeriodUnit: ProductResolver.PeriodUnit? = .month,
        subscriptionPeriodValue: Int? = 1,
        introOfferPaymentMode: ProductResolver.IntroPaymentMode? = nil,
        introOfferPeriodUnit: ProductResolver.PeriodUnit? = nil,
        introOfferPeriodValue: Int? = nil,
        introOfferDisplayPrice: String? = nil
    ) {
        self.id = id
        self.displayPrice = displayPrice
        self.price = price
        self.subscriptionPeriodUnit = subscriptionPeriodUnit
        self.subscriptionPeriodValue = subscriptionPeriodValue
        self.introOfferPaymentMode = introOfferPaymentMode
        self.introOfferPeriodUnit = introOfferPeriodUnit
        self.introOfferPeriodValue = introOfferPeriodValue
        self.introOfferDisplayPrice = introOfferDisplayPrice
    }
}
