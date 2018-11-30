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
    lazy var testEntryConfigurations: [TestEntryConfiguration] = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test_progressive_splitter() {
        let result = progressiveSplitter.split(
            inputs: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        
        XCTAssertEqual(result[0], Array(testEntryConfigurations[0..<4]))
        XCTAssertEqual(result[1], Array(testEntryConfigurations[4..<7]))
        XCTAssertEqual(result[2], Array(testEntryConfigurations[7..<9]))
        XCTAssertEqual(result[3], Array(testEntryConfigurations[9..<10]))
    }
}
