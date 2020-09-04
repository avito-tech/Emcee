import Foundation
import Graphite
import Metrics
import QueueModels
import RunnerModels

public final class TimeToStartTestMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: timeToStartTest,
            timestamp: timestamp
        )
    }
}
