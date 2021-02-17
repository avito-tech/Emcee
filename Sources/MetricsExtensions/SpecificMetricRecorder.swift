import Foundation
import Metrics
import Graphite
import Statsd

/// Metric recorder that is bound to a specific context. Usually it relates to a test being executed, e.g. its configuration might be coming from a `Bucket`.
public protocol SpecificMetricRecorder: MetricRecorder {
    
}

public final class SpecificMetricRecorderWrapper: SpecificMetricRecorder {
    private let wrappedRecorder: MetricRecorder
    
    public init(_ wrappedRecorder: MetricRecorder) {
        self.wrappedRecorder = wrappedRecorder
    }
    
    public func capture(_ metric: GraphiteMetric) {
        wrappedRecorder.capture(metric)
    }
    
    public func capture(_ metric: StatsdMetric) {
        wrappedRecorder.capture(metric)
    }
    
    public func tearDown(timeout: TimeInterval) {
        wrappedRecorder.tearDown(timeout: timeout)
    }
}
