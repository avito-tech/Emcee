import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerTestHelpers
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class BucketGeneratorTests: XCTestCase {
    lazy var testDestination1 = TestDestinationFixtures.testDestination
    lazy var testDestination2 = assertDoesNotThrow { try TestDestination(deviceType: "device2", runtime: "11.0") }
    
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
        
        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )
        
        let buckets = splitter.generateBuckets(
            testEntryConfigurations: testEntryConfigurations,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
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

        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generateBuckets(
            testEntryConfigurations: testEntryConfigurations,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
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

        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generateBuckets(
            testEntryConfigurations: testEntryConfigurations,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
        )
        XCTAssertEqual(buckets.count, 3)
        XCTAssertEqual(
            try buckets[0].payload.cast(RunIosTestsPayload.self).testEntries,
            expectedBucketEntries
        )
        XCTAssertEqual(
            try buckets[1].payload.cast(RunIosTestsPayload.self).testEntries,
            expectedBucketEntries
        )
        XCTAssertEqual(
            try buckets[2].payload.cast(RunIosTestsPayload.self).testEntries,
            expectedBucketEntries
        )
    }
}
