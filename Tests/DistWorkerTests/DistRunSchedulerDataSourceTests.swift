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
                toolResources: ToolResourcesFixtures.fakeToolResources()
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

