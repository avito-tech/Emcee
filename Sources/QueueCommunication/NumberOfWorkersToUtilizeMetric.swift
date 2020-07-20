import Foundation
import Metrics
import QueueModels

public final class NumberOfWorkersToUtilizeMetric: Metric {
    public init(
        emceeVersion: Version,
        queueHost: String,
        workersCount: Int
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "workers",
                "utilizable",
                "count"
            ],
            variableComponents: [
                emceeVersion.value,
                queueHost,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: Double(workersCount),
            timestamp: Date()
        )
    }
}
