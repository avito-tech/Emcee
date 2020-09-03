import Foundation
import Metrics
import QueueModels

public final class SimulatorAllocationDurationMetric: GraphiteMetric {
    public init(
        host: String,
        duration: Double,
        allocatedSuccessfully: Bool,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "simulator",
                "allocation",
                "duration",
            ],
            variableComponents: [
                host,
                allocatedSuccessfully ? "success" : "failure",
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
