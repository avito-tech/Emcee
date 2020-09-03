import Foundation
import Metrics
import QueueModels

public final class JobCountMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(jobCount),
            timestamp: timestamp
        )
    }
}
