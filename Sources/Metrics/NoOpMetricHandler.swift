import Foundation
import Graphite
import Statsd

public final class NoOpMetricHandler: GraphiteMetricHandler, StatsdMetricHandler {
    public init() {}
    public func handle(metric: GraphiteMetric) {}
    public func handle(metric: StatsdMetric) {}
    public func tearDown(timeout: TimeInterval) {}
}
