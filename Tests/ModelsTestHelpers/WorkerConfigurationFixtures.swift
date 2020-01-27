import Foundation
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        analyticsConfiguration: AnalyticsConfiguration(
            graphiteConfiguration: nil,
            sentryConfiguration: nil
        ),
        reportAliveInterval: 42,
        requestSignature: PayloadSignature(value: "requestSignature"),
        testRunExecutionBehavior: TestRunExecutionBehavior(
            numberOfSimulators: 2
        )
    )
}
