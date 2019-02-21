import Foundation
@testable import Graphite
import XCTest

final class GraphiteMetricTests: XCTestCase {
    func test___invalid_paths() {
        XCTAssertThrowsError(try GraphiteMetric(path: ["key "], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: [""], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["."], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["path.anotherpath"], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["\n"], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["\t"], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: [" "], value: 0, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["🥶"], value: 0, timestamp: Date()))
    }
    
    func test___valid_path() {
        XCTAssertNoThrow(try GraphiteMetric(path: ["path"], value: 0, timestamp: Date()))
    }
    
    func test___invalid_values() {
        XCTAssertThrowsError(try GraphiteMetric(path: ["component"], value: .nan, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["component"], value: .signalingNaN, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["component"], value: .infinity, timestamp: Date()))
        XCTAssertThrowsError(try GraphiteMetric(path: ["component"], value: -.infinity, timestamp: Date()))
    }
}
