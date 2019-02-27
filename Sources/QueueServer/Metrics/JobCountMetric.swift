import Foundation
import Metrics

public final class JobCountMetric: Metric {
    public init(
        queueHost: String, 
        jobCount: Int
        ) 
    {
        super.init(
            fixedComponents: [
                "queue",
                "jobs",
                "count"
            ],
            variableComponents: [
                queueHost,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(jobCount),
            timestamp: Date()
        )
    }
}
