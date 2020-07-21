import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerTestHelpers
import ScheduleStrategy
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class IndividualBucketSplitterTests: XCTestCase {
    let individualSplitter = IndividualBucketSplitter(
        uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
    )
    let testEntries = [
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4")
    ]
    lazy var testEntryConfigurations = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test__individual_splitter__splits_to_entries_with_single_test() {
        let buckets = individualSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1)
        )
        XCTAssertEqual(buckets.map { $0.testEntries }, testEntries.map { [$0] })
    }
    
    func test_individual_splitter_splits_tests_regardless_of_number_of_destinations() {
        XCTAssertEqual(
            individualSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfo(numberOfWorkers: 1)
            ),
            individualSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfo(numberOfWorkers: 5)
            )
        )
    }
}
