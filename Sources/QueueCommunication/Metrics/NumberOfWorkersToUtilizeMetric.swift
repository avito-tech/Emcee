import Foundation
import Graphite
import Metrics
import QueueModels

public final class NumberOfWorkersToUtilizeMetric: GraphiteMetric {
    public init(
        emceeVersion: Version,
        queueHost: String,
        workersCount: Int
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "workers",
                "utilizable",
                "count"
            ],
            variableComponents: [
                emceeVersion.value,
                queueHost,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: Double(workersCount),
            timestamp: Date()
        )
    }
}
