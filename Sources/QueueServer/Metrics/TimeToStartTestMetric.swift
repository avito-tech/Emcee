import Foundation
import Metrics
import Models

public final class TimeToStartTestMetric: Metric {
    public init(
        testEntry: TestEntry,
        timeToStartTest: TimeInterval
        )
    {
        super.init(
            fixedComponents: [
                "tests",
                "time_to_start"
            ],
            variableComponents: [
                testEntry.testName.className,
                testEntry.testName.methodName,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeToStartTest,
            timestamp: Date()
        )
    }
}
