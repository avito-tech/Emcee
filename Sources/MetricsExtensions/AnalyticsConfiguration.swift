import Foundation

public struct AnalyticsConfiguration: Codable, Hashable {
    public let graphiteConfiguration: MetricConfiguration?
    public let statsdConfiguration: MetricConfiguration?
    public let kibanaConfiguration: KibanaConfiguration?

    public init(
        graphiteConfiguration: MetricConfiguration? = nil,
        statsdConfiguration: MetricConfiguration? = nil,
        kibanaConfiguration: KibanaConfiguration? = nil
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.statsdConfiguration = statsdConfiguration
        self.kibanaConfiguration = kibanaConfiguration
    }
}
