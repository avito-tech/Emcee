import Foundation
import Metrics

class FakeMetricHandler: MetricHandler {
    var metrics = [Metric]()
    
    func handle(metric: Metric) {
        metrics.append(metric)
    }
    
    var tearDownTimeout: TimeInterval = 0
    
    func tearDown(timeout: TimeInterval) {
        tearDownTimeout = timeout
    }
}
