import Foundation
import Metrics
import Models

public final class StuckBucketsMetric: Metric {
    public init(
        count: Int,
        host: WorkerId,
        reason: String,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "stuck"
            ],
            variableComponents: [
                reason,
                host.value,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(count),
            timestamp: timestamp
        )
    }
}
