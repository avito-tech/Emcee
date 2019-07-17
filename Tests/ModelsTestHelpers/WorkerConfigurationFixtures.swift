import Foundation
import Models

public final class WorkerConfigurationFixtures {
    public static let workerConfiguration = WorkerConfiguration(
        testRunExecutionBehavior: TestRunExecutionBehavior(
            numberOfSimulators: 2,
            scheduleStrategy: .equallyDivided
        ),
        testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 400),
        pluginUrls: [],
        reportAliveInterval: 42,
        requestSignature: RequestSignature(value: "requestSignature")
    )
}
