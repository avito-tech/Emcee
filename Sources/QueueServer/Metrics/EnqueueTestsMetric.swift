import Foundation
import Graphite
import MetricsRecording
import QueueModels

/// Indicates an event when you enqueue some tests
public final class EnqueueTestsMetric: GraphiteMetric {
    public init(
        version: Version,
        queueHost: String,
        numberOfTests: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "enqueue"
            ],
            variableComponents: [
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
