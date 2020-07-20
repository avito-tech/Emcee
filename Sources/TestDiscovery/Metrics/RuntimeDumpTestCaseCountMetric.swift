import Foundation
import Metrics
import QueueModels

public final class RuntimeDumpTestCaseCountMetric: Metric {
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTestCases),
            timestamp: timestamp
        )
    }
}
