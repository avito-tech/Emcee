import Foundation
import Metrics
import Models

public final class TimeToStartTestMetric: Metric {
    public init(
        testEntry: TestEntry,
        timeToStartTest: TimeInterval,
        version: Version,
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeToStartTest,
            timestamp: timestamp
        )
    }
}
