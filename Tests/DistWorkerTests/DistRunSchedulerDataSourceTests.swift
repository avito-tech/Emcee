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
                environment: ["a": "b"],
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                testDestination: TestDestinationFixtures.testDestination,
                toolResources: ToolResourcesFixtures.fakeToolResources()
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

