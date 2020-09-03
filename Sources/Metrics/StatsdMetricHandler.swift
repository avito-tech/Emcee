import Foundation

public protocol StatsdMetricHandler {
    func handle(metric: StatsdMetric)
    func tearDown(timeout: TimeInterval)
}
