import Foundation
import Metrics

public final class RuntimeDumpTestCaseCountMetric: Metric {
    public init(testBundleName: String, numberOfTestCases: Int) {
        super.init(
            fixedComponents: [
                "runtime_dump",
                "test_case_count"
            ],
            variableComponents: [
                testBundleName,
                "reserved",
                "reserved",
                "reserved",
                "reserved"
            ],
            value: Double(numberOfTestCases),
            timestamp: Date()
        )
    }
}
