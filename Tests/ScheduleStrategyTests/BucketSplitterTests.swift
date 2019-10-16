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
        
        let splitter = UnsplitBucketSplitter(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )
        
        let buckets = splitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        XCTAssertEqual(buckets.count, 2)
    }

    func test_splits_same_tests_in_different_buckets_with_one_test() {
        let testEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"))
                .with(testDestination: testDestination1)
                .testEntryConfigurations()

        let splitter = UnsplitBucketSplitter(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        XCTAssertEqual(buckets.count, 4)
    }

    func test_splits_same_tests_in_different_buckets_with_many_tests() {
        let testEntryConfigurations =
            TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"))
                .add(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"))
                .with(testDestination: testDestination1)
                .testEntryConfigurations()
        let expectedBucketEntries = [
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3")
        ]

        let splitter = UnsplitBucketSplitter(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture()
        )
        XCTAssertEqual(buckets.count, 3)
        XCTAssertEqual(buckets[0].testEntries, expectedBucketEntries)
        XCTAssertEqual(buckets[1].testEntries, expectedBucketEntries)
        XCTAssertEqual(buckets[2].testEntries, expectedBucketEntries)
    }
}
