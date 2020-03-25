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
        numberOfSimulators: 2,
        payloadSignature: PayloadSignature(value: "payloadSignature")
    )
}
