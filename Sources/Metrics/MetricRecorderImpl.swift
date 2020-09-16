import Foundation
import Graphite
import Statsd

public final class MetricRecorderImpl: MutableMetricRecorder {
    private var graphiteMetricHandler: GraphiteMetricHandler
    private var statsdMetricHandler: StatsdMetricHandler
    private let queue: DispatchQueue
    
    public init(
        graphiteMetricHandler: GraphiteMetricHandler,
        statsdMetricHandler: StatsdMetricHandler,
        queue: DispatchQueue = DispatchQueue(label: "MetricRecorderImpl.syncQueue")
    ) {
        self.graphiteMetricHandler = graphiteMetricHandler
        self.statsdMetricHandler = statsdMetricHandler
        self.queue = queue
    }
    
    public func setGraphiteMetric(handler: GraphiteMetricHandler) {
        queue.async { [weak self] in
            self?.graphiteMetricHandler.tearDown(timeout: 10)
            self?.graphiteMetricHandler = handler
        }
    }
    
    public func setStatsdMetric(handler: StatsdMetricHandler) {
        queue.async { [weak self] in
            self?.statsdMetricHandler.tearDown(timeout: 10)
            self?.statsdMetricHandler = handler
        }
    }
    
    public func capture(_ metric: GraphiteMetric) {
        queue.async { [weak self] in
            self?.graphiteMetricHandler.handle(metric: metric)
        }
    }
    
    public func capture(_ metric: StatsdMetric) {
        queue.async { [weak self] in
            self?.statsdMetricHandler.handle(metric: metric)
        }
    }
    
    public func tearDown(timeout: TimeInterval) {
        queue.sync { [weak self] in
            self?.graphiteMetricHandler.tearDown(timeout: timeout)
            self?.statsdMetricHandler.tearDown(timeout: timeout)
        }
    }
}
