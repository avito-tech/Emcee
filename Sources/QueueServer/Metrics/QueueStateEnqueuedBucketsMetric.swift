import Foundation
import Metrics

public final class QueueStateEnqueuedBucketsMetric: Metric {
    public init(host: String,  numberOfEnqueuedBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued"
            ],
            variableComponents: [
                host,
                "reserved",
                "reserved",
                "reserved",
                "reserved"
            ],
            value: Double(numberOfEnqueuedBuckets),
            timestamp: Date()
        )
    }
}
