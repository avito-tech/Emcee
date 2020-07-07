import Foundation
import Metrics
import Models

public final class TimeToDequeueBucket: Metric {
    public init(
        timeInterval: TimeInterval,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "time_to_dequeue"
            ],
            variableComponents: [
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeInterval,
            timestamp: timestamp
        )
    }
}
