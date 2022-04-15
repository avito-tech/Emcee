import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class QueueStateDequeuedTestsMetric: GraphiteMetric {
    public init(
        queueHost: String,
        numberOfDequeuedTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "dequeued_tests",
            ],
            variableComponents: [
                queueHost,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: Double(numberOfDequeuedTests),
            timestamp: timestamp
        )
    }
}
