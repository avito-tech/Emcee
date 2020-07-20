import Foundation
import Metrics
import QueueModels

public final class JobCountMetric: Metric {
    public init(
        queueHost: String, 
        version: Version,
        jobCount: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "jobs",
                "count"
            ],
            variableComponents: [
                queueHost,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(jobCount),
            timestamp: timestamp
        )
    }
}
