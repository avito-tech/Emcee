import Foundation
import Metrics
import QueueModels
import SimulatorPoolModels

public final class SimulatorDurationMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
