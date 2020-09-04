import Foundation
import Graphite
import Metrics
import QueueModels

public final class TestFinishedMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: 1,
            timestamp: timestamp
        )
    }
}
