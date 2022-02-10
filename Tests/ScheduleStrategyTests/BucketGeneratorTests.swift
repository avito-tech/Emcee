import AppleTestModelsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class BucketGeneratorTests: XCTestCase {
    lazy var simDeviceType1 = SimDeviceTypeFixture.fixture("device1")
    lazy var simDeviceType2 = SimDeviceTypeFixture.fixture("device2")
    
    func test_splits_into_matrix_of_test_destination_by_test_entry() {
        let testEntries = [
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4"),
        ]
        
        let configuredTestEntries =
        testEntries.map { testEntry in
            ConfiguredTestEntryFixture()
                .with(testEntry: testEntry)
                .with(
                    testEntryConfiguration: TestEntryConfigurationFixtures().with(
                        appleTestConfiguration: AppleTestConfigurationFixture()
                            .with(simDeviceType: simDeviceType1)
                            .appleTestConfiguration()
                    ).testEntryConfiguration()
                )
                .build()
        } +
        testEntries.map { testEntry in
            ConfiguredTestEntryFixture()
                .with(testEntry: testEntry)
                .with(
                    testEntryConfiguration: TestEntryConfigurationFixtures().with(
                        appleTestConfiguration: AppleTestConfigurationFixture()
                            .with(simDeviceType: simDeviceType2)
                            .appleTestConfiguration()
                    ).testEntryConfiguration()
                )
                .build()
        }
        
        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )
        
        let buckets = splitter.generateBuckets(
            configuredTestEntries: configuredTestEntries,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
        )
        XCTAssertEqual(buckets.count, 2)
    }

    func test_splits_same_tests_in_different_buckets_with_one_test() {
        let testEntries: [TestEntry] = Array(
            repeating: TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"),
            count: 4
        )
        
        let configuredTestEntries =
        testEntries.map { testEntry in
            ConfiguredTestEntryFixture()
                .with(testEntry: testEntry)
                .with(
                    testEntryConfiguration: TestEntryConfigurationFixtures().with(
                        appleTestConfiguration: AppleTestConfigurationFixture()
                            .with(simDeviceType: simDeviceType1)
                            .appleTestConfiguration()
                    ).testEntryConfiguration()
                )
                .build()
        }

        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generateBuckets(
            configuredTestEntries: configuredTestEntries,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
        )
        XCTAssertEqual(buckets.count, 4)
    }

    func test_splits_same_tests_in_different_buckets_with_many_tests() {
        let testEntries = [
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
        ]
        
        let configuredTestEntries =
        testEntries.map { testEntry in
            ConfiguredTestEntryFixture()
                .with(testEntry: testEntry)
                .with(
                    testEntryConfiguration: TestEntryConfigurationFixtures().with(
                        appleTestConfiguration: AppleTestConfigurationFixture()
                            .with(simDeviceType: simDeviceType1)
                            .appleTestConfiguration()
                    ).testEntryConfiguration()
                )
                .build()
        }

        let expectedBucketEntries = [
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
            TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3")
        ]

        let splitter = BucketGeneratorImpl(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        )

        let buckets = splitter.generateBuckets(
            configuredTestEntries: configuredTestEntries,
            splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            testSplitter: UnsplitBucketSplitter()
        )
        XCTAssertEqual(buckets.count, 3)
        
        for bucket in buckets {
            switch bucket.payloadContainer {
            case .runAppleTests(let runAppleTestsPayload):
                assert { runAppleTestsPayload.testEntries } equals: {
                    expectedBucketEntries
                }
            case .runAndroidTests:
                failTest("Unexpected payload")
            }
        }
    }
}
