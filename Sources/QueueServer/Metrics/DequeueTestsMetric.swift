import Foundation
import Metrics
import Models

public final class DequeueTestsMetric: Metric {
    public init(
        workerId: WorkerId,
        version: Version,
        numberOfTests: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "dequeue"
            ],
            variableComponents: [
                workerId.value,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
