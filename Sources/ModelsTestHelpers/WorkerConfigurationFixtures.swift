import Foundation
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        testRunExecutionBehavior: TestRunExecutionBehavior(
            numberOfRetries: 1,
            numberOfSimulators: 2,
            environment: [:],
            scheduleStrategy: .equallyDivided),
        testTimeoutConfiguration: TestTimeoutConfiguration(
            singleTestMaximumDuration: 400),
        reportAliveInterval: 42)
}
