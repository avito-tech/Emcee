import Foundation
import Metrics
import XCTest

final class MetricHandlerTests: XCTestCase {
    let metricHandler = FakeMetricHandler()
    let metric = Metric(
        fixedComponents: ["fixed"],
        variableComponents: ["variable"],
        value: 33,
        timestamp: Date()
    )
    
    func test___global_metric_handler_captures_metric() {
        GlobalMetricConfig.metricHandler = metricHandler
        MetricRecorder.capture(metric)
        
        XCTAssertEqual(metricHandler.metrics, [metric])
    }
}

