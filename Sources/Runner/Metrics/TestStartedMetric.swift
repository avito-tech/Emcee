import Foundation
import Graphite
import Metrics
import QueueModels

public final class TestStartedMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: 1,
            timestamp: timestamp
        )
    }
}
