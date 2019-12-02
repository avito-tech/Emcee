import Foundation
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        analyticsConfiguration: AnalyticsConfiguration(
            graphiteConfiguration: nil,
            sentryConfiguration: nil
        ),
        pluginUrls: [],
        reportAliveInterval: 42,
        requestSignature: RequestSignature(value: "requestSignature"),
        testRunExecutionBehavior: TestRunExecutionBehavior(
            numberOfSimulators: 2
        )
    )
}
