import Foundation

public protocol MetricHandler {
    func handle(metric: Metric)
    func tearDown(timeout: TimeInterval)
}
