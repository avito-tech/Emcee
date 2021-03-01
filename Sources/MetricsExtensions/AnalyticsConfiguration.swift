import Foundation

public struct AnalyticsConfiguration: Codable, Hashable {
    public let graphiteConfiguration: MetricConfiguration?
    public let statsdConfiguration: MetricConfiguration?

    public init(
        graphiteConfiguration: MetricConfiguration? = nil,
        statsdConfiguration: MetricConfiguration? = nil
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.statsdConfiguration = statsdConfiguration
    }
}
