import Foundation

/// This metric handler will handle all captured metrics.
public final class GlobalMetricConfig {
    public static var graphiteMetricHandler: GraphiteMetricHandler = NoOpMetricHandler()
    public static var statsdMetricHandler: StatsdMetricHandler = NoOpMetricHandler()
}
