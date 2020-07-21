import Foundation
import Metrics
import QueueModels
import RunnerModels

public final class TimeToStartTestMetric: Metric {
    public init(
        testEntry: TestEntry,
        version: Version,
        queueHost: String,
        timeToStartTest: TimeInterval,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "tests",
                "time_to_start"
            ],
            variableComponents: [
                testEntry.testName.className,
                testEntry.testName.methodName,
                version.value,
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeToStartTest,
            timestamp: timestamp
        )
    }
}
