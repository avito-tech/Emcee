import Foundation
import Metrics

public final class EnqueueBucketsMetric: Metric {
    public init(numberOfBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "enqueue"
            ],
            variableComponents: [
                "reserved",
                "reserved",
                "reserved",
                "reserved"
            ],
            value: Double(numberOfBuckets),
            timestamp: Date()
        )
    }
}
