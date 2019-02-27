import Foundation
import Metrics

public final class StuckBucketsMetric: Metric {
    /// - Parameter count: number of stuck buckets
    /// - Parameter host: where buckets have stuck
    /// - Parameter reason: why runner decided buckets have stuck.
    public init(
        count: Int,
        host: String,
        reason: String)
    {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "stuck"
            ],
            variableComponents: [
                reason,
                host,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(count),
            timestamp: Date()
        )
    }
}
