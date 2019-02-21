import Foundation

public final class NoOpMetricHandler: MetricHandler {
    public func handle(metric: Metric) {}
    public func tearDown(timeout: TimeInterval) {}
}
