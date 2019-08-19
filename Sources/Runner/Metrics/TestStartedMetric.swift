import Foundation
import Metrics

public final class TestStartedMetric: Metric {
    public init(
        host: String,
        testClassName: String,
        testMethodName: String)
    {
        super.init(
            fixedComponents: ["test", "started"],
            variableComponents: [
                host,
                testClassName,
                testMethodName,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: 1,
            timestamp: Date()
        )
    }
}
