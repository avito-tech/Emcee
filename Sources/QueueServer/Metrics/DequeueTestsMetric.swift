import Foundation
import Metrics

public final class DequeueTestsMetric: Metric {
    public init(workerId: String, numberOfTests: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "dequeue"
            ],
            variableComponents: [
                workerId,
                "reserved",
                "reserved",
                "reserved",
                "reserved"
            ],
            value: Double(numberOfTests),
            timestamp: Date()
        )
    }
}
