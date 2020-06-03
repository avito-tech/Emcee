import Foundation
import Metrics

public final class SimulatorAllocationDurationMetric: Metric {
    public init(
        host: String,
        duration: Double,
        allocatedSuccessfully: Bool
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: duration,
            timestamp: Date()
        )
    }
}
