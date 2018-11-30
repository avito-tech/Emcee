import Foundation
import Models
import ModelsTestHelpers
import ScheduleStrategy
import XCTest

final class IndividualBucketSplitterTests: XCTestCase {
    let individualSplitter = IndividualBucketSplitter()
    let testEntries = [
        TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
    ]
    lazy var testEntryConfigurations = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test__individual_splitter__splits_to_entries_with_single_test() {
        let buckets = individualSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture())
        XCTAssertEqual(buckets.map { $0.testEntries }, testEntries.map { [$0] })
    }
    
    func test_individual_splitter_splits_tests_regardless_of_number_of_destinations() {
        XCTAssertEqual(
            individualSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: 1)),
            individualSplitter.generate(
                inputs: testEntryConfigurations,
                splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: 5)))
    }
}
