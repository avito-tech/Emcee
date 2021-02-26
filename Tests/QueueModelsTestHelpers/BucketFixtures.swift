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
        return Bucket(
            analyticsConfiguration: AnalyticsConfiguration(),
            bucketId: bucketId,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            developerDir: .current,
            pluginLocations: [],
            simulatorControlTool: SimulatorControlToolFixtures.simctlTool,
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testEntries: testEntries,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: numberOfRetries),
            testRunnerTool: .xcodebuild,
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testType: TestType.uiTest,
            workerCapabilityRequirements: workerCapabilityRequirements,
            persistentMetricsJobId: ""
        )
    }
}
