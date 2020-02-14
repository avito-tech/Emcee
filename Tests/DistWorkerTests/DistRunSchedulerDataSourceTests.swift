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
                developerDir: .current,
                pluginLocations: [],
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                testDestination: TestDestinationFixtures.testDestination,
                testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a": "b"]).build(),
                testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                testType: .uiTest,
                toolResources: ToolResourcesFixtures.fakeToolResources()
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

