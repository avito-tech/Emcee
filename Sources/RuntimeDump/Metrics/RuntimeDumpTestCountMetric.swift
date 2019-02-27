import Foundation
import Metrics

public final class RuntimeDumpTestCountMetric: Metric {
    public init(testBundleName: String, numberOfTests: Int) {
        super.init(
            fixedComponents: [
                "runtime_dump",
                "test_count"
            ],
            variableComponents: [
                testBundleName,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: Date()
        )
    }
}
