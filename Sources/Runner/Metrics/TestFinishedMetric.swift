import Foundation
import Metrics

public final class TestFinishedMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String,
        testsFinishedCount: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "finished"],
            variableComponents: [
                result,
                host,
                testClassName,
                testMethodName,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(testsFinishedCount),
            timestamp: timestamp
        )
    }
}
