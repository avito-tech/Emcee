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
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            developerDir: .current,
            pluginLocations: [],
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testEntries: testEntries,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: numberOfRetries),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testType: TestType.uiTest,
            toolResources: ToolResourcesFixtures.fakeToolResources()
        )
    }
}
