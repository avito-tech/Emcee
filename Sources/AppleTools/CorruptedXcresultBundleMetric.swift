import Foundation
import QueueModels
import Graphite

public final class CorruptedXcresultBundleMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
            ],
            value: 1.0,
            timestamp: timestamp
        )
    }
}

