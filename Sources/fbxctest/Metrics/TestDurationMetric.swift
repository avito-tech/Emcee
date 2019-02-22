import Foundation
import Metrics

public final class TestDurationMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String,
        duration: Double)
    {
        super.init(
            fixedComponents: ["test", "duration"],
            variableComponents: [
                result,
                host,
                testClassName,
                testMethodName,
                "reserved",
                "reserved",
                "reserved"
            ],
            value: duration,
            timestamp: Date()
        )
    }
}
