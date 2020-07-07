import Foundation
import Metrics
import Models

public final class SimulatorDurationMetric: Metric {
    public enum Action: String {
        case create
        case boot
        case shutdown
        case delete
    }
    
    public init(
        action: Action,
        host: String,
        testDestination: TestDestination,
        isSuccessful: Bool,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "simulator",
                "action",
                "duration",
            ],
            variableComponents: [
                action.rawValue,
                host,
                testDestination.deviceType,
                testDestination.runtime,
                isSuccessful ? "success" : "failure",
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
