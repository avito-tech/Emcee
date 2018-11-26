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
    
    func test__individual_splitter__splits_to_entries_with_single_test() {
        let actualEntries = individualSplitter.split(
            inputs: testEntries,
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture())
        XCTAssertEqual(actualEntries, testEntries.map { [$0] })
    }
    
    func test_individual_splitter_splits_tests_regardless_of_number_of_destinations() {
        XCTAssertEqual(
            individualSplitter.split(
                inputs: testEntries,
                bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: 1)),
            individualSplitter.split(
                inputs: testEntries,
                bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: 5)))
    }
}
