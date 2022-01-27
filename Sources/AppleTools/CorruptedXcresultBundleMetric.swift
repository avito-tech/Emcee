import Foundation
import QueueModels
import Statsd

public final class CorruptedXcresultBundleMetric: StatsdMetric {
    public init(
        host: String,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "test",
                "corrupted_xcresult_bundle",
            ],
            variableComponents: [
                host,
                version.value,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
            ],
            value: .count(1)
        )
    }
}

