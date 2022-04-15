import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class QueueStateEnqueuedTestsMetric: GraphiteMetric {
    public init(
        queueHost: String,
        numberOfEnqueuedTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued_tests",
            ],
            variableComponents: [
                queueHost,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: Double(numberOfEnqueuedTests),
            timestamp: timestamp
        )
    }
}
