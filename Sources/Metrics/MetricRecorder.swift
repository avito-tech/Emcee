import Foundation
import Graphite
import Statsd

public protocol MetricRecorder {
    func capture(_ metric: GraphiteMetric)
    func capture(_ metric: StatsdMetric)
    func tearDown(timeout: TimeInterval)
}

extension MetricRecorder {
    public func capture(_ metrics: [GraphiteMetric]) {
        metrics.forEach(capture)
    }
    
    public func capture(_ metrics: [StatsdMetric]) {
        metrics.forEach(capture)
    }
    
    public func capture(_ metrics: GraphiteMetric...) {
        capture(metrics)
    }
    
    public func capture(_ metrics: StatsdMetric...) {
        capture(metrics)
    }
}
