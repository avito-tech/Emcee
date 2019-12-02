import DistWorker
import Models
import ModelsTestHelpers
import Scheduler
import XCTest

final class DistRunSchedulerDataSourceTests: XCTestCase {
    func test() {
        let handler: () -> SchedulerBucket? = {
            SchedulerBucket(
                bucketId: "id",
                testEntries: [TestEntryFixtures.testEntry()],
                buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                testDestination: TestDestinationFixtures.testDestination,
                testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a": "b"]).build(),
                testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                testType: .uiTest,
                toolResources: ToolResourcesFixtures.fakeToolResources(),
                toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

