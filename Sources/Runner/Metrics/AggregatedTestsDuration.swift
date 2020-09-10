import Foundation
import Metrics
import QueueModels
import Statsd

public final class AggregatedTestsDuration: StatsdMetric {
    public init(
        result: String,
        host: String,
        version: Version,
        persistentMetricsJobId: String,
        duration: TimeInterval
    ) {
        super.init(
            fixedComponents: ["test", "duration"],
            variableComponents: [
                host,
                version.value,
                persistentMetricsJobId,
                result,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField
            ],
            value: .time(duration)
        )
    }
}
