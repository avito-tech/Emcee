import Foundation
import Statsd
import QueueModels

public final class JobPreparationDurationMetric: StatsdMetric {
    public init(
        queueHost: String,
        version: Version,
        persistentMetricsJobId: String,
        successful: Bool,
        duration: TimeInterval
    ) {
        super.init(
            fixedComponents: ["job", "preparation"],
            variableComponents: [
                queueHost,
                version.value,
                persistentMetricsJobId,
                successful ? "success" : "failure",
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
