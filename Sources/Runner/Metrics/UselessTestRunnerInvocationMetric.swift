import Foundation
import Metrics
import QueueModels

public final class UselessTestRunnerInvocationMetric: Metric {
    public init(
        host: String,
        version: Version,
        duration: TimeInterval,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "test",
                "useless_runner_invocation",
            ],
            variableComponents: [
                host,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
