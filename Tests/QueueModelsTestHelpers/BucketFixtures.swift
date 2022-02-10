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
        bucketPayloadContainer: BucketPayloadContainer? = nil,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = []
    ) -> Bucket {
        let bucketPayloadContainer = bucketPayloadContainer ?? .runAppleTests(Self.createrunAppleTestsPayload())
        
        return Bucket.newBucket(
            bucketId: bucketId,
            analyticsConfiguration: AnalyticsConfiguration(),
            workerCapabilityRequirements: workerCapabilityRequirements,
            payloadContainer: bucketPayloadContainer
        )
    }
    
    public static func createrunAppleTestsPayload(
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0
    ) -> RunAppleTestsPayload {
        RunAppleTestsPayload(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            developerDir: .current,
            pluginLocations: [],
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            simDeviceType: SimDeviceTypeFixture.fixture(),
            simRuntime: SimRuntimeFixture.fixture(),
            testEntries: testEntries,
            testExecutionBehavior: TestExecutionBehavior(
                environment: [:],
                userInsertedLibraries: [],
                numberOfRetries: numberOfRetries,
                testRetryMode: .retryThroughQueue,
                logCapturingMode: .noLogs,
                runnerWasteCleanupPolicy: .clean
            ),
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: 0,
                testRunnerMaximumSilenceDuration: 0
            ),
            testAttachmentLifetime: .deleteOnSuccess
        )
    }
}
