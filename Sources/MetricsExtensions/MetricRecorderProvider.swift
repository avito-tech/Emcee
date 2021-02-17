import Foundation
import Metrics

public protocol MutableMetricRecorderProvider {
    func metricRecorder() -> MutableMetricRecorder
}

public final class MutableMetricRecorderProviderImpl: MutableMetricRecorderProvider {
    private let queue: DispatchQueue
    
    public init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    public func metricRecorder() -> MutableMetricRecorder {
        MetricRecorderImpl(
            graphiteMetricHandler: NoOpMetricHandler(),
            statsdMetricHandler: NoOpMetricHandler(),
            queue: queue
        )
    }
}
