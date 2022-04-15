import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class RuntimeDumpTestCountMetric: GraphiteMetric {
    public init(
        testBundleName: String,
        numberOfTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "runtime_dump",
                "test_count"
            ],
            variableComponents: [
                testBundleName,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
