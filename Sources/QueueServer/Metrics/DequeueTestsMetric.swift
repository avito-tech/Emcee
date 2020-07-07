import Foundation
import Metrics
import Models

public final class DequeueTestsMetric: Metric {
    public init(
        workerId: WorkerId,
        version: Version,
        queueHost: String,
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
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
