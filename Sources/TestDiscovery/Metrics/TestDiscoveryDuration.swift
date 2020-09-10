import Foundation
import Metrics
import QueueModels
import Statsd

public final class TestDiscoveryDuration: StatsdMetric {
    public init(
        host: String,
        version: Version,
        persistentMetricsJobId: String,
        isSuccessful: Bool,
        duration: TimeInterval
    ) {
        super.init(
            fixedComponents: ["test", "discovery", "duration"],
            variableComponents: [
                host,
                version.value,
                persistentMetricsJobId,
                isSuccessful ? "success" : "failure",
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
                StatsdMetric.reservedField,
            ],
            value: .time(duration)
        )
    }
}
