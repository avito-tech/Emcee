import Foundation
import Metrics

public final class FakeMetricHandler: MetricHandler {
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
