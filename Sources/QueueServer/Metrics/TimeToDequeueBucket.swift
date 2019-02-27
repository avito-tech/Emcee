import Foundation
import Metrics

public final class TimeToDequeueBucket: Metric {
    public init(timeInterval: TimeInterval) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "time_to_dequeue"
            ],
            variableComponents: [
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeInterval,
            timestamp: Date()
        )
    }
}
