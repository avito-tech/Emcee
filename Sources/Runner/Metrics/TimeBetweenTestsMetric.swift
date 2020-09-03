import Foundation
import Metrics
import QueueModels

public final class TimeBetweenTestsMetric: GraphiteMetric {
    public init(
        host: String,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "test",
                "between_tests",
                "duration",
            ],
            variableComponents: [
                host,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
