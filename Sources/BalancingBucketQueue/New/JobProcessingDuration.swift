import Foundation
import Metrics
import QueueModels
import Statsd

public final class JobProcessingDuration: StatsdMetric {
    public init(
        queueHost: String,
        version: Version,
        persistentMetricsJobId: String,
        duration: TimeInterval
    ) {
        super.init(
            fixedComponents: ["job", "duration"],
            variableComponents: [
                queueHost,
                version.value,
                persistentMetricsJobId,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
            ],
            value: .time(duration)
        )
    }
}
