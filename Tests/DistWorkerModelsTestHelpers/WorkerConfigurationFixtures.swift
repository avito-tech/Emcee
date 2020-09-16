import DistWorkerModels
import Foundation
import LoggingSetup
import QueueModels

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        numberOfSimulators: 2,
        payloadSignature: PayloadSignature(value: "payloadSignature")
    )
}
