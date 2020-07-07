import Foundation
import Metrics
import Models

public final class SimulatorAllocationDurationMetric: Metric {
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
