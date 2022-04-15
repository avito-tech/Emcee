import Graphite
import Statsd
import Foundation
import MetricsRecording

/// A metric recorder for global purposes. Its metrics do not depend on specific test run.
public protocol GlobalMetricRecorder: MutableMetricRecorder {
    
}

public final class GlobalMetricRecorderImpl: GlobalMetricRecorder {
    private let recorder: MutableMetricRecorder
    
    public init(
        graphiteHandler: GraphiteMetricHandler = NoOpMetricHandler(),
        statsdHandler: StatsdMetricHandler = NoOpMetricHandler(),
        queue: DispatchQueue = DispatchQueue(label: "GlobalMetricRecorderImpl.queue")
    ) {
        recorder = MetricRecorderImpl(
            graphiteMetricHandler: graphiteHandler,
            statsdMetricHandler: statsdHandler,
            queue: queue
        )
    }
    
    public func capture(_ metric: GraphiteMetric) {
        recorder.capture(metric)
    }
    
    public func capture(_ metric: StatsdMetric) {
        recorder.capture(metric)
    }
    
    public func tearDown(timeout: TimeInterval) {
        recorder.tearDown(timeout: timeout)
    }
    
    public func setGraphiteMetric(handler: GraphiteMetricHandler) throws {
        try recorder.setGraphiteMetric(handler: handler)
    }
    
    public func setStatsdMetric(handler: StatsdMetricHandler) throws {
        try recorder.setStatsdMetric(handler: handler)
    }
}
