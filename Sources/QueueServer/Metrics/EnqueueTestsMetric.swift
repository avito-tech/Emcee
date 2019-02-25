import Foundation
import Metrics

/// Indicates an event when you enqueue some tests
public final class EnqueueTestsMetric: Metric {
    public init(numberOfTests: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "enqueue"
            ],
            variableComponents: [
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
