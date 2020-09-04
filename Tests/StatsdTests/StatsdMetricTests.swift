import Metrics
import Statsd
import XCTest

final class StatsdMetricTests: XCTestCase {
    func test___building___for_gauge() {
        XCTAssertEqual(
            StatsdMetric(
                fixedComponents: ["c", "d"],
                variableComponents: ["e", "f"],
                value: .gauge(1)
            ).build(domain: ["a", "b"]),
            "a.b.c.d.e.f:1|g"
        )
    }
    
    func test___building___for_time() {
        XCTAssertEqual(
            StatsdMetric(
                fixedComponents: ["c", "d"],
                variableComponents: ["e", "f"],
                value: .time(1)
            ).build(domain: ["a", "b"]),
            "a.b.c.d.e.f:1000|ms"
        )
    }
}
