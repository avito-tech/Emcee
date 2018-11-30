import Foundation
import Foundation
import Models
import ModelsTestHelpers
import ScheduleStrategy
import XCTest

final class EquallyDividedBucketSplitterTests: XCTestCase {
    let equallyDividedSplitter = EquallyDividedBucketSplitter()
    let testEntries = [
        TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
    ]
    lazy var testEntryConfigurations = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test_equally_divided_splitter__splits_to_buckets_with_equal_size() {
        let expected = testEntryConfigurations.splitToChunks(withSize: 2)
        
        let actual = equallyDividedSplitter.split(
            inputs: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: 2))
        
        XCTAssertEqual(actual, expected)
    }
    
    func test_equally_divided_splitter__respects_number_of_destinations() {
        let expected = testEntryConfigurations.splitToChunks(withSize: 1)
        
        let actual = equallyDividedSplitter.split(
            inputs: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(numberOfDestinations: UInt(testEntries.count)))
        
        XCTAssertEqual(actual, expected)
    }
}

