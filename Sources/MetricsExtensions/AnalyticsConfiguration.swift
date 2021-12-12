import Foundation

public struct AnalyticsConfiguration: Codable, Hashable, CustomStringConvertible {
    public let graphiteConfiguration: MetricConfiguration?
    public let statsdConfiguration: MetricConfiguration?
    public let kibanaConfiguration: KibanaConfiguration?
    
    public let persistentMetricsJobId: String?
    public let metadata: [String: String]?

    public init(
        graphiteConfiguration: MetricConfiguration? = nil,
        statsdConfiguration: MetricConfiguration? = nil,
        kibanaConfiguration: KibanaConfiguration? = nil,
        persistentMetricsJobId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.graphiteConfiguration = graphiteConfiguration
        self.statsdConfiguration = statsdConfiguration
        self.kibanaConfiguration = kibanaConfiguration
        self.persistentMetricsJobId = persistentMetricsJobId
        self.metadata = metadata
    }
    
    public var description: String {
        var result: [String] = []
        result.append("graphite " + (graphiteConfiguration == nil ? "disabled": "enabled"))
        result.append("statsd " + (statsdConfiguration == nil ? "disabled": "enabled"))
        result.append("kibana " + (kibanaConfiguration == nil ? "disabled": "enabled"))
        
        return "<\(type(of: self)): " + result.joined(separator: ";") + ">"
    }
}
