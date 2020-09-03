import Foundation
import Sentry

public struct AnalyticsConfiguration: Codable, Equatable {
    public let graphiteConfiguration: MetricConfiguration?
    public let statsdConfiguration: MetricConfiguration?
    public let sentryConfiguration: SentryConfiguration?

    public init(
        graphiteConfiguration: MetricConfiguration?,
        statsdConfiguration: MetricConfiguration?,
        sentryConfiguration: SentryConfiguration?
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.statsdConfiguration = statsdConfiguration
        self.sentryConfiguration = sentryConfiguration
    }
}
