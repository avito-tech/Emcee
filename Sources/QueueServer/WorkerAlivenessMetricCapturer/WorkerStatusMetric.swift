import Foundation
import Metrics
import QueueModels

public final class WorkerStatusMetric: GraphiteMetric {
    public init(
        workerId: WorkerId,
        status: String,
        version: Version,
        queueHost: String,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "worker",
                "status",
            ],
            variableComponents: [
                workerId.value,
                status,
                version.value,
                queueHost,
            ],
            value: 1.0,
            timestamp: timestamp
        )
    }
}
