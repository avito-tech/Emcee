import BuildArtifactsTestHelpers
import DistWorker
import MetricsExtensions
import QueueModels
import RunnerModels
import RunnerTestHelpers
import Scheduler
import SimulatorPoolTestHelpers
import XCTest

final class DistRunSchedulerDataSourceTests: XCTestCase {
    func test() {
        let handler: () -> SchedulerBucket? = {
            SchedulerBucket(
                bucketId: "id",
                analyticsConfiguration: AnalyticsConfiguration(),
                pluginLocations: [],
                runTestsBucketPayload: RunTestsBucketPayload(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    simulatorControlTool: SimulatorControlToolFixtures.simctlTool,
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testEntries: [TestEntryFixtures.testEntry()],
                    testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a": "b"]).build(),
                    testRunnerTool: .xcodebuild,
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
                    testType: .uiTest
                )
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

