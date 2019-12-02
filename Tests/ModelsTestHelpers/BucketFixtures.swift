import Foundation
import Models

public final class BucketFixtures {
    public static func createBucket(
        bucketId: BucketId = BucketId(value: "BucketFixturesFixedBucketId"),
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0
    ) -> Bucket {
        return Bucket(
            bucketId: bucketId,
            testEntries: testEntries,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: numberOfRetries),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testType: TestType.uiTest,
            toolResources: ToolResourcesFixtures.fakeToolResources(),
            toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
        )
    }
}
