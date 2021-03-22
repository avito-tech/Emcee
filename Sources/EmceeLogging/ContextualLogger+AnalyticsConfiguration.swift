import Foundation
import MetricsExtensions

public extension ContextualLogger {
    func with(analyticsConfiguration: AnalyticsConfiguration) -> ContextualLogger {
        self
            .withMetadata(key: .persistentMetricsJobId, value: analyticsConfiguration.persistentMetricsJobId)
            .withMetadata(analyticsConfiguration.metadata ?? [:])
    }
}
