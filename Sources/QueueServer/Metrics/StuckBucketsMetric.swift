import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class StuckBucketsMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(count),
            timestamp: timestamp
        )
    }
}
