import Foundation
import Graphite
import Metrics
import Statsd

public final class NoOpMetricRecorder: MetricRecorder {
    public init() {}
    
    public func capture(_ metric: GraphiteMetric) {}
    public func capture(_ metric: StatsdMetric) {}
    public func tearDown(timeout: TimeInterval) {}
}
