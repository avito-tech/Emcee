import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class DequeueTestsMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
