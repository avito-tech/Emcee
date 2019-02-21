import Foundation

/// This metric handler will handle all captured metrics.
public final class GlobalMetricConfig {
    public static var metricHandler: MetricHandler = NoOpMetricHandler()
}
