import Foundation

struct CreateShopperSessionVariables: Encodable {

    // MARK: - Required

    let osType: String
    let token: String
    let tokenType: String
    let contextId: String
    let returnAppUrl: String
    let cancelAppUrl: String

    // MARK: - Optional — derived internally

    let osVersion: String?
    let fallbackUrlScheme: String?
    let buyerEmailAddressMerchantPassed: String?
    let paypalNativeAppInstalled: Bool?
    let bnCode: String?
    let integrationChannel: String?
    let sdkVersion: String?

    // MARK: - Optional — not currently wired

    let paymentMethodSelected: String?
    let productCode: String?
    let paymentType: String?
}
