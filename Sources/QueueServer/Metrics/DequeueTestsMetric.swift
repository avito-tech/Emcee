import Foundation
import Metrics
import Models

public final class DequeueTestsMetric: Metric {
    public init(workerId: WorkerId, numberOfTests: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "dequeue"
            ],
            variableComponents: [
                workerId.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: Date()
        )
    }
}
