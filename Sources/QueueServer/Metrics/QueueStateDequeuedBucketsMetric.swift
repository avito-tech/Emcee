import Foundation
import Metrics

public final class QueueStateDequeuedBucketsMetric: Metric {
    public init(host: String,  numberOfDequeuedBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "dequeued"
            ],
            variableComponents: [
                host,
                "reserved",
                "reserved",
                "reserved",
                "reserved"
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: Date()
        )
    }
}
