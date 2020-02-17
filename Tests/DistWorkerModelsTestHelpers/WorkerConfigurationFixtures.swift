import DistWorkerModels
import Foundation
import LoggingSetup
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        analyticsConfiguration: AnalyticsConfiguration(
            graphiteConfiguration: nil,
            sentryConfiguration: nil
        ),
        reportAliveInterval: 42,
        payloadSignature: PayloadSignature(value: "payloadSignature"),
        testRunExecutionBehavior: TestRunExecutionBehavior(
            numberOfSimulators: 2
        )
    )
}
