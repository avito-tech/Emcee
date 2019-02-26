import Foundation
import Metrics
import Models
import LocalHostDeterminer

public final class QueueStateMetricRecorder {
    private let state: QueueState

    public init(state: QueueState) {
        self.state = state
    }
    
    public func capture() {
        let host = LocalHostDeterminer.currentHostAddress
        MetricRecorder.capture(
            QueueStateEnqueuedBucketsMetric(host: host, numberOfEnqueuedBuckets: state.enqueuedBucketCount),
            QueueStateDequeuedBucketsMetric(host: host, numberOfDequeuedBuckets: state.dequeuedBucketCount)
        )
    }
}
