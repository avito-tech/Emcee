import Foundation
import Graphite
import Metrics
import QueueModels

public final class UselessTestRunnerInvocationMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
