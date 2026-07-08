import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CorePayments)
import CorePayments
#endif

/// Coordinates the GraphQL call that pre-warms a Shopper Session with app-switch eligibility.
@_documentation(visibility: private)
public class CreateShopperSessionAPI {

    // MARK: - Private Properties

    private let coreConfig: CoreConfig
    private let networkingClient: NetworkingClient

    private let createShopperSessionQuery = """
        mutation CreateShopperSessionWithAppSwitchEligibility(
            $osType: OSType!
            $osVersion: String
            $token: Token!
            $tokenType: TokenType!
            $contextId: String!
            $buyerEmailAddressMerchantPassed: EmailAddress
            $paypalNativeAppInstalled: Boolean
            $bnCode: String
            $integrationChannel: AppSwitchIntegrationChannel
            $paymentMethodSelected: PaymentMethodSelected
            $productCode: AppSwitchProductCode
            $paymentType: PaymentType
            $returnAppUrl: String
            $cancelAppUrl: String
            $fallbackUrlScheme: String
            $sdkVersion: String
        ) {
            createShopperSessionWithAppSwitchEligibility(
                appSwitchEligibilityInput: {
                    osType: $osType
                    osVersion: $osVersion
                    token: $token
                    tokenType: $tokenType
                    contextId: $contextId
                    buyerEmailAddressMerchantPassed: $buyerEmailAddressMerchantPassed
                    paypalNativeAppInstalled: $paypalNativeAppInstalled
                    merchantOptInForAppSwitch: true
                    experimentationContext: {
                        bnCode: $bnCode
                        merchantCountry: "US"
                        integrationChannel: $integrationChannel
                        paymentMethodSelected: $paymentMethodSelected
                        productCode: $productCode
                        paymentType: $paymentType
                    }
                }
                shopperSessionInput: {
                    returnAppUrl: $returnAppUrl
                    cancelAppUrl: $cancelAppUrl
                    fallbackUrlScheme: $fallbackUrlScheme
                    sdkVersion: $sdkVersion
                }
            ) {
                appSwitchEligibilityResponse {
                    appSwitchEligible
                    ineligibleReason
                    redirectURL
                }
                shopperSessionResponse {
                    sessionId
                    expiresAt
                }
            }
        }
        """

    // MARK: - Initializer

    public init(coreConfig: CoreConfig) {
        self.coreConfig = coreConfig
        self.networkingClient = NetworkingClient(coreConfig: coreConfig)
    }

    /// Exposed for injecting `MockNetworkingClient` in tests.
    init(coreConfig: CoreConfig, networkingClient: NetworkingClient) {
        self.coreConfig = coreConfig
        self.networkingClient = networkingClient
    }

    // MARK: - Internal Methods

    /// Creates a Shopper Session with app-switch eligibility and returns the full result.
    /// - Parameters:
    ///   - contextId: A merchant-provided context identifier for the session (e.g. order ID or correlation ID).
    ///   - token: The merchant token value (order ID or client token).
    ///   - tokenType: The type of token — use `ExternalTokenKind.orderId` or `ExternalTokenKind.clientToken`.
    ///   - urlConfig: Return, cancel, and fallback deep-link URLs registered with PayPal.
    ///   - userIdentity: Optional buyer identity. The email address is forwarded to the GQL mutation.
    /// - Returns: A `ShopperSessionResult` containing eligibility, redirect URL, and session config.
    /// - Throws: A `CoreSDKError` if the network call or response parsing fails.
    func createShopperSessionWithAppSwitchEligibility(
        contextId: String,
        token: String,
        tokenType: String,
        urlConfig: PayPalURLConfig,
        userIdentity: PayPalUserIdentity?
    ) async throws -> ShopperSessionResult {

        #if canImport(UIKit)
        let osVersion: String? = UIDevice.current.systemVersion
        #else
        let osVersion: String? = nil
        #endif

        let variables = CreateShopperSessionVariables(
            osType: PayPalCoreConstants.osType,
            token: token,
            tokenType: tokenType,
            contextId: contextId,
            returnAppUrl: urlConfig.returnAppURL.absoluteString,
            cancelAppUrl: urlConfig.cancelAppURL.absoluteString,
            osVersion: osVersion,
            fallbackUrlScheme: urlConfig.fallbackSchemeURL?.absoluteString,
            buyerEmailAddressMerchantPassed: userIdentity?.email,
            paypalNativeAppInstalled: nil,
            bnCode: coreConfig.bnCode,
            integrationChannel: PayPalCoreConstants.integrationChannel,
            sdkVersion: PayPalCoreConstants.payPalSDKVersion,
            paymentMethodSelected: nil,
            productCode: nil,
            paymentType: nil
        )

        let graphQLRequest = GraphQLRequest(
            query: createShopperSessionQuery,
            variables: variables,
            queryNameForURL: nil
        )

        let httpResponse = try await networkingClient.fetch(request: graphQLRequest)

        let parsed: CreateShopperSessionResponse = try HTTPResponseParser()
            .parseGraphQL(httpResponse, as: CreateShopperSessionResponse.self)

        guard let result = parsed.shopperSession else {
            throw NetworkingError.noGraphQLDataKey
        }

        return result
    }
}
