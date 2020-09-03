import Foundation
import Metrics
import MetricsTestHelpers
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
        
        GlobalMetricConfig.graphiteMetricHandler = metricHandler
        MetricRecorder.capture(metric)
        
        XCTAssertEqual(metricHandler.metrics, [metric])
    }
    
    func test___global_metric_handler___captures_statsd_metric() {
        let metricHandler = FakeMetricHandler<StatsdMetric>()
        let metric = StatsdMetric(
            fixedComponents: ["fixed"],
            variableComponents: ["variable"],
            value: .gauge(1)
        )
        
        GlobalMetricConfig.statsdMetricHandler = metricHandler
        MetricRecorder.capture(metric)
        
        XCTAssertEqual(metricHandler.metrics, [metric])
    }
}

