import Foundation
import Metrics
import Models

public final class StuckBucketsMetric: Metric {
    public init(
        workerId: WorkerId,
        reason: String,
        version: Version,
        queueHost: String,
        count: Int,
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
                workerId.value,
                version.value,
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(count),
            timestamp: timestamp
        )
    }
}
