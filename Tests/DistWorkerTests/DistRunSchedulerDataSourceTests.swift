import BuildArtifactsTestHelpers
import DistWorker
import Models
import ModelsTestHelpers
import RunnerTestHelpers
import Scheduler
import SimulatorPoolTestHelpers
import XCTest

final class DistRunSchedulerDataSourceTests: XCTestCase {
    func test() {
        let handler: () -> SchedulerBucket? = {
            SchedulerBucket(
                bucketId: "id",
                buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                developerDir: .current,
                pluginLocations: [],
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                testDestination: TestDestinationFixtures.testDestination,
                testEntries: [TestEntryFixtures.testEntry()],
                testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a": "b"]).build(),
                testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
                testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                testType: .uiTest
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

