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
        bucketPayload: BucketPayload? = nil,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = []
    ) -> Bucket {
        let bucketPayload = bucketPayload ?? .runIosTests(Self.createRunIosTestsPayload())
        
        return Bucket.newBucket(
            bucketId: bucketId,
            analyticsConfiguration: AnalyticsConfiguration(),
            workerCapabilityRequirements: workerCapabilityRequirements,
            payload: bucketPayload
        )
    }
    
    public static func createRunIosTestsPayload(
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0
    ) -> RunIosTestsPayload {
        RunIosTestsPayload(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            developerDir: .current,
            pluginLocations: [],
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testEntries: testEntries,
            testExecutionBehavior: TestExecutionBehavior(
                environment: [:],
                numberOfRetries: numberOfRetries,
                testRetryMode: .retryThroughQueue
            ),
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: 0,
                testRunnerMaximumSilenceDuration: 0
            )
        )
    }
}
