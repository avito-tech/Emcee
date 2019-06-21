import Foundation
import Models
import ModelsTestHelpers
import ScheduleStrategy
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class BucketSplitterTests: XCTestCase {
    let testDestination1 = TestDestinationFixtures.testDestination
    let testDestination2 = try! TestDestination(deviceType: "device2", runtime: "11.0")
    
    func test_splits_into_matrix_of_test_destination_by_test_entry() {
        let testEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4"))
                .with(testDestination: testDestination1)
                .testEntryConfigurations()
                +
                TestEntryConfigurationFixtures()
                    .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"))
                    .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"))
                    .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"))
                    .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4"))
                    .with(testDestination: testDestination2)
                    .testEntryConfigurations()
        
        let splitter = ContinuousBucketSplitter(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )
        
        let buckets = splitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        XCTAssertEqual(buckets.count, 2)
        
        // TODO: add more checks
    }
}
