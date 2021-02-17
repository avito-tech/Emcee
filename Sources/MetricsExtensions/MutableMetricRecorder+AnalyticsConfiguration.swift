import Graphite
import Metrics
import Statsd

extension MutableMetricRecorder {
    public func set(analyticsConfiguration: AnalyticsConfiguration) throws {
        let graphiteMetricHandler: GraphiteMetricHandler
        if let graphiteConfiguration = analyticsConfiguration.graphiteConfiguration {
            graphiteMetricHandler = try GraphiteMetricHandlerImpl(
                graphiteDomain: graphiteConfiguration.metricPrefix.components(separatedBy: "."),
                graphiteSocketAddress: graphiteConfiguration.socketAddress
            )
        } else {
            graphiteMetricHandler = NoOpMetricHandler()
        }
        
        let statsdMetricHandler: StatsdMetricHandler
        if let statsdConfiguration = analyticsConfiguration.statsdConfiguration {
            statsdMetricHandler = try StatsdMetricHandlerImpl(
                statsdDomain: statsdConfiguration.metricPrefix.components(separatedBy: "."),
                statsdClient: StatsdClientImpl(statsdSocketAddress: statsdConfiguration.socketAddress)
            )
        } else {
            statsdMetricHandler = NoOpMetricHandler()
        }
        
        try setGraphiteMetric(handler: graphiteMetricHandler)
        try setStatsdMetric(handler: statsdMetricHandler)
    }
}
