import Models
import ModelsTestHelpers
@testable import ScheduleStrategy
import XCTest

final class ProgressiveSplitterTests: XCTestCase {
    let progressiveSplitter = ProgressiveBucketSplitter()
    
    let testEntries = [
        TestEntry(className: "class", methodName: "testMethod0", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod4", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod5", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod6", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod7", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod8", caseId: nil),
        TestEntry(className: "class", methodName: "testMethod9", caseId: nil)
    ]
    
    func test_progressive_splitter() {
        let result = progressiveSplitter.split(
            inputs: testEntries,
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture())
        XCTAssertEqual(
            result[0],
            [
                TestEntry(className: "class", methodName: "testMethod0", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod3", caseId: nil)
            ])
        XCTAssertEqual(
            result[1],
            [
                TestEntry(className: "class", methodName: "testMethod4", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod5", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod6", caseId: nil)
            ])
        XCTAssertEqual(
            result[2],
            [
                TestEntry(className: "class", methodName: "testMethod7", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod8", caseId: nil)
            ])
        XCTAssertEqual(
            result[3],
            [
                TestEntry(className: "class", methodName: "testMethod9", caseId: nil)
            ])
    }
}
