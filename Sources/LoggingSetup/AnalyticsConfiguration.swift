import Foundation
import Sentry

public struct AnalyticsConfiguration: Codable, Equatable {
    public let graphiteConfiguration: GraphiteConfiguration?
    public let sentryConfiguration: SentryConfiguration?

    public init(
        graphiteConfiguration: GraphiteConfiguration?,
        sentryConfiguration: SentryConfiguration?
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.sentryConfiguration = sentryConfiguration
    }
}
