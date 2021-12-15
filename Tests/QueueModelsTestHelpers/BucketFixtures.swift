import BuildArtifacts
import BuildArtifactsTestHelpers
import Foundation
import MetricsExtensions
import QueueModels
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import WorkerCapabilitiesModels

public final class BucketFixtures {
    public static func createBucket(
        bucketId: BucketId = BucketId(value: "BucketFixturesFixedBucketId"),
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = []
    ) -> Bucket {
        return Bucket.newBucket(
            bucketId: bucketId,
            analyticsConfiguration: AnalyticsConfiguration(),
            workerCapabilityRequirements: workerCapabilityRequirements,
            payload: Payload(
                buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                developerDir: .current,
                pluginLocations: [],
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                testDestination: TestDestinationFixtures.testDestination,
                testEntries: testEntries,
                testExecutionBehavior: TestExecutionBehavior(
                    environment: [:],
                    userInsertedLibraries: [],
                    numberOfRetries: numberOfRetries,
                    testRetryMode: .retryThroughQueue
                ),
                testTimeoutConfiguration: TestTimeoutConfiguration(
                    singleTestMaximumDuration: 0,
                    testRunnerMaximumSilenceDuration: 0
                )
            )
        )
    }
}
