import Foundation
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        testExecutionBehavior: TestExecutionBehavior(
            numberOfRetries: 1,
            numberOfSimulators: 2,
            environment: [:],
            scheduleStrategy: .equallyDivided),
        testTimeoutConfiguration: TestTimeoutConfiguration(
            singleTestMaximumDuration: 400),
        reportAliveInterval: 42)
}
