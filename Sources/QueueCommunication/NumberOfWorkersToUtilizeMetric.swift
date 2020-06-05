import Foundation
import Metrics
import Models

public final class NumberOfWorkersToUtilizeMetric: Metric {
    public init(
        emceeVersion: Version,
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: Double(workersCount),
            timestamp: Date()
        )
    }
}
