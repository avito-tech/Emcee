import Foundation

public final class AnalyticsConfiguration: Codable, Equatable {
    public let graphiteConfiguration: GraphiteConfiguration?
    public let sentryConfiguration: SentryConfiguration?

    public init(
        graphiteConfiguration: GraphiteConfiguration?,
        sentryConfiguration: SentryConfiguration?
        )
    {
        self.graphiteConfiguration = graphiteConfiguration
        self.sentryConfiguration = sentryConfiguration
    }
    
    public static func == (left: AnalyticsConfiguration, right: AnalyticsConfiguration) -> Bool {
        return left.graphiteConfiguration == right.graphiteConfiguration
            && left.sentryConfiguration == right.sentryConfiguration
    }
}
