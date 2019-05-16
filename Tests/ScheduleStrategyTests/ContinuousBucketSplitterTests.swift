import Foundation
import Models
import ModelsTestHelpers
import ScheduleStrategy
import XCTest

final class ContinuousBucketSplitterTests: XCTestCase {
    let continuousSplitter = ContinuousBucketSplitter()
    let testEntries = [
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4")
    ]
    lazy var testEntryConfigurations = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test__continuos_splitter__splits_to_entry_with_all_test() {
        let buckets = continuousSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        XCTAssertEqual(buckets.map { $0.testEntries }, [testEntries])
    }
    
    func test_continuos_splitter_splits_tests_regardless_of_number_of_destinations() {
        XCTAssertEqual(
            continuousSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfWorkers: 1)),
            continuousSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfWorkers: 5)))
    }
}

