import Foundation
import Metrics

public final class TestFinishedMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String,
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
            value: 1,
            timestamp: timestamp
        )
    }
}
