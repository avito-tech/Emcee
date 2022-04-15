import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class RuntimeDumpTestCaseCountMetric: GraphiteMetric {
    public init(
        testBundleName: String,
        numberOfTestCases: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "runtime_dump",
                "test_case_count"
            ],
            variableComponents: [
                testBundleName,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfTestCases),
            timestamp: timestamp
        )
    }
}
