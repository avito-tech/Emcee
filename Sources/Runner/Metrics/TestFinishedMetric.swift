import Foundation
import Metrics
import QueueModels

public final class TestFinishedMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "finished"],
            variableComponents: [
                result,
                host,
                testClassName,
                testMethodName,
                version.value,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: 1,
            timestamp: timestamp
        )
    }
}
