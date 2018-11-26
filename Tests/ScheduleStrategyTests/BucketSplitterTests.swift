import Foundation
import Models
import ModelsTestHelpers
import ScheduleStrategy
import XCTest

final class BucketSplitterTests: XCTestCase {
    let testEntries = [
        TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
    ]
    let testDestination1 = TestDestinationFixtures.testDestination
    let testDestination2 = try! TestDestination(deviceType: "device2", runtime: "11.0")
    
    func test_splits_into_matrix_of_test_destination_by_test_entry() {
        let splitter = IndividualBucketSplitter()
        
        let buckets = splitter.generate(
            inputs: testEntries,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(testDestinations: [testDestination1, testDestination2]))
        XCTAssertEqual(buckets.count, testEntries.count * 2)
    }
}
