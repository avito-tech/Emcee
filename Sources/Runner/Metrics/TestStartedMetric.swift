import Foundation
import Metrics
import Models

public final class TestStartedMetric: Metric {
    public init(
        host: String,
        testClassName: String,
        testMethodName: String,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "started"],
            variableComponents: [
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
