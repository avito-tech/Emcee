import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import ScheduleStrategy
import TestHelpers
import XCTest

final class IndividualBucketSplitterTests: XCTestCase {
    let individualSplitter = IndividualBucketSplitter()
    let testEntries = [
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4"),
    ]
    lazy var configuredTestEntries = testEntries.map { testEntry in
        ConfiguredTestEntry(
            testEntry: testEntry,
            testEntryConfiguration: TestEntryConfigurationFixtures().testEntryConfiguration()
        )
    }
    
    func test___individual_splitter_splits_to_buckets_with_single_test() {
        let groups = individualSplitter.split(
            configuredTestEntries: configuredTestEntries,
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 4)
        )
        assert {
            groups
        } equals: {
            configuredTestEntries.map { [$0] }
        }
    }
    
    func test___individual_splitter_splits_same_way_regardless_of_number_of_destinations() {
        XCTAssertEqual(
            individualSplitter.split(
                configuredTestEntries: configuredTestEntries,
                bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1)
            ),
            individualSplitter.split(
                configuredTestEntries: configuredTestEntries,
                bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 5, numberOfParallelBuckets: 10)
            )
        )
    }
}
