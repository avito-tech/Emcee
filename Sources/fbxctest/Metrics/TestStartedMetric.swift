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
                "reserved",
                "reserved",
                "reserved"
            ],
            value: 1,
            timestamp: Date()
        )
    }
}
