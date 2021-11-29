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
                payload: Payload(
                    buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
                    developerDir: .current,
                    simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
                    simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                    testDestination: TestDestinationFixtures.testDestination,
                    testEntries: [TestEntryFixtures.testEntry()],
                    testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a": "b"]).build(),
                    testTimeoutConfiguration: TestTimeoutConfiguration(
                        singleTestMaximumDuration: 0,
                        testRunnerMaximumSilenceDuration: 0
                    )
                )
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

