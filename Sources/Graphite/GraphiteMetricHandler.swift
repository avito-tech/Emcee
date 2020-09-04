import Foundation

public protocol GraphiteMetricHandler {
    func handle(metric: GraphiteMetric)
    func tearDown(timeout: TimeInterval)
}
