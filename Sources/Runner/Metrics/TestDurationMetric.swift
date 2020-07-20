import Foundation
import Metrics
import QueueModels

public final class TestDurationMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "duration"],
            variableComponents: [
                result,
                host,
                testClassName,
                testMethodName,
                version.value,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
