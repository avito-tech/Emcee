import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class TestPostflightMetric: GraphiteMetric {
    public init(
        host: String,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "postflight"],
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
