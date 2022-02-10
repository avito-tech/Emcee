import BuildArtifactsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import DistWorker
import MetricsExtensions
import QueueModels
import QueueModelsTestHelpers
import Scheduler
import SimulatorPoolTestHelpers
import XCTest

final class DistRunSchedulerDataSourceTests: XCTestCase {
    func test() {
        let handler: () -> SchedulerBucket? = {
            SchedulerBucket(
                analyticsConfiguration: AnalyticsConfiguration(),
                bucketId: "id",
                bucketPayloadContainer: .runAppleTests(
                    RunAppleTestsPayloadFixture().runAppleTestsPayload()
                )
            )
        }
        let dataSource = DistRunSchedulerDataSource(onNextBucketRequest: handler)
        
        XCTAssertEqual(handler(), dataSource.nextBucket())
    }
}

