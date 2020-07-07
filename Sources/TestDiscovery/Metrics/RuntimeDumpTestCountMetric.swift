import Foundation
import Metrics
import Models

public final class RuntimeDumpTestCountMetric: Metric {
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
