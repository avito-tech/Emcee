import Foundation
import Metrics

public final class DequeueBucketsMetric: Metric {
    public init(workerId: String, numberOfBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "dequeue"
            ],
            variableComponents: [
                workerId,
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
