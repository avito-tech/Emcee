import Foundation
import Graphite
import Metrics
import MetricsTestHelpers
import Statsd
import XCTest

final class MetricHandlerTests: XCTestCase {
    func test___global_metric_handler___captures_graphite_metric() {
        let metricHandler = FakeMetricHandler<GraphiteMetric>()
        let metric = GraphiteMetric(
            fixedComponents: ["fixed"],
            variableComponents: ["variable"],
            value: 33,
            timestamp: Date()
        )
        
        let queue = DispatchQueue(label: "test")
        let recorder = MetricRecorderImpl(
            graphiteMetricHandler: metricHandler,
            statsdMetricHandler: NoOpMetricHandler(),
            queue: queue
        )
        recorder.capture(metric)
        
        queue.sync { }
        XCTAssertEqual(metricHandler.metrics, [metric])
    }
    
    func test___global_metric_handler___captures_statsd_metric() {
        let metricHandler = FakeMetricHandler<StatsdMetric>()
        let metric = StatsdMetric(
            fixedComponents: ["fixed"],
            variableComponents: ["variable"],
            value: .gauge(1)
        )
        
        let queue = DispatchQueue(label: "test")
        let recorder = MetricRecorderImpl(
            graphiteMetricHandler: NoOpMetricHandler(),
            statsdMetricHandler: metricHandler,
            queue: queue
        )
        recorder.capture(metric)
        
        queue.sync { }
        XCTAssertEqual(metricHandler.metrics, [metric])
    }
}

