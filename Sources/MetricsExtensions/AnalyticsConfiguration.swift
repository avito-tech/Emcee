import Foundation
import Sentry

public struct AnalyticsConfiguration: Codable, Hashable {
    public let graphiteConfiguration: MetricConfiguration?
    public let statsdConfiguration: MetricConfiguration?
    public let sentryConfiguration: SentryConfiguration?

    public init(
        graphiteConfiguration: MetricConfiguration? = nil,
        statsdConfiguration: MetricConfiguration? = nil,
        sentryConfiguration: SentryConfiguration? = nil
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.statsdConfiguration = statsdConfiguration
        self.sentryConfiguration = sentryConfiguration
    }
}
