import Foundation
import Graphite
import Metrics
import Statsd

public final class FakeMetricHandler<Metric> {
    public var metrics = [Metric]()
    
    public init() {}
    
    public func handle(metric: Metric) {
        metrics.append(metric)
    }
    
    public var tearDownTimeout: TimeInterval = 0
    
    public func tearDown(timeout: TimeInterval) {
        tearDownTimeout = timeout
    }
}

extension FakeMetricHandler: GraphiteMetricHandler where Metric == GraphiteMetric {}
extension FakeMetricHandler: StatsdMetricHandler where Metric == StatsdMetric {}
