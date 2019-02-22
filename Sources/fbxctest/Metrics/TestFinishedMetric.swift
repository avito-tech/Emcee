import Foundation
import Metrics

public final class TestFinishedMetric: Metric {
    public init(
        result: String,
        host: String,
        testClassName: String,
        testMethodName: String)
    {
        super.init(
            fixedComponents: ["test", "finished"],
            variableComponents: [
                result,
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
