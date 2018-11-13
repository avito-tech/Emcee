import Models
import ModelsTestHelpers
@testable import ScheduleStrategy
import XCTest

class ScheduleStrategyTests: XCTestCase {
    let fakeToolResources = ToolResourcesFixtures.fakeToolResources()
    let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    
    func test_individualStrategy_splitsTestsIntoBucketsOfOne() throws {
        let destination = try TestDestination(deviceType: "device", iOSVersion: "11.0")
        let testEntries = [
            TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod3", caseId: nil)
        ]
        
        let buckets = IndividualScheduleStrategy().generateBuckets(
            numberOfDestinations: 1,
            testEntries: testEntries,
            testDestination: destination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
            .map {
                Bucket(
                    testEntries: $0.testEntries,
                    testDestination: $0.testDestination,
                    toolResources: $0.toolResources,
                    buildArtifacts: $0.buildArtifacts)
            }
        
        let expectedBuckets = testEntries.map {
            Bucket(testEntries: [$0], testDestination: destination, toolResources: fakeToolResources, buildArtifacts: fakeBuildArtifacts)
        }
        XCTAssertEqual(buckets, expectedBuckets)
    }
    
    func test_individualStrategy_splitsTestsIntoBucketsOfOne_regardlessDestinationCount() throws {
        let destination = try TestDestination(deviceType: "device", iOSVersion: "11.0")
        let testEntries = [
            TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
        ]
        
        XCTAssertEqual(
            IndividualScheduleStrategy().generateBuckets(
                numberOfDestinations: 1,
                testEntries: testEntries,
                testDestination: destination,
                toolResources: fakeToolResources,
                buildArtifacts: fakeBuildArtifacts).count,
            IndividualScheduleStrategy().generateBuckets(
                numberOfDestinations: 2,
                testEntries: testEntries,
                testDestination: destination,
                toolResources: fakeToolResources,
                buildArtifacts: fakeBuildArtifacts).count)
    }
    
    func test_equallyDividedStrategy_splitsToBucketsWithEqualSizes() throws {
        let destination = try TestDestination(deviceType: "device", iOSVersion: "11.0")
        let testEntries = [
            TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
        ]
        
        let expectedBuckets = testEntries.splitToChunks(withSize: 2).map {
            Bucket(testEntries: $0, testDestination: destination, toolResources: fakeToolResources, buildArtifacts: fakeBuildArtifacts)
        }
        
        let buckets = EquallyDividedScheduleStrategy().generateBuckets(
            numberOfDestinations: 2,
            testEntries: testEntries,
            testDestination: destination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
            .map {
                Bucket(
                    testEntries: $0.testEntries,
                    testDestination: $0.testDestination,
                    toolResources: $0.toolResources,
                    buildArtifacts: $0.buildArtifacts)
            }
        XCTAssertEqual(buckets, expectedBuckets)
    }
    
    func test_equallyDividedStrategy_respectsDestinationCount() throws {
        let destination = try TestDestination(deviceType: "device", iOSVersion: "11.0")
        let testEntries = [
            TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod3", caseId: nil),
            TestEntry(className: "class", methodName: "testMethod4", caseId: nil)
        ]
        
        let expectedBuckets = testEntries.map {
            Bucket(testEntries: [$0], testDestination: destination, toolResources: fakeToolResources, buildArtifacts: fakeBuildArtifacts)
        }
        
        let buckets = EquallyDividedScheduleStrategy().generateBuckets(
            numberOfDestinations: 4,
            testEntries: testEntries,
            testDestination: destination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
            .map {
                Bucket(
                    testEntries: $0.testEntries,
                    testDestination: $0.testDestination,
                    toolResources: $0.toolResources,
                    buildArtifacts: $0.buildArtifacts)
            }
        XCTAssertEqual(buckets, expectedBuckets)
    }
    
    func test_progressiveStrategy() throws {
        let destination = try TestDestination(deviceType: "device", iOSVersion: "11.0")
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
        
        let buckets = ProgressiveScheduleStrategy().generateBuckets(
            numberOfDestinations: 1,
            testEntries: testEntries,
            testDestination: destination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        XCTAssertEqual(
            buckets[0].testEntries,
            [
                TestEntry(className: "class", methodName: "testMethod0", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod1", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod2", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod3", caseId: nil)
            ])
        XCTAssertEqual(
            buckets[1].testEntries,
            [
                TestEntry(className: "class", methodName: "testMethod4", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod5", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod6", caseId: nil)
            ])
        XCTAssertEqual(
            buckets[2].testEntries,
            [
                TestEntry(className: "class", methodName: "testMethod7", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod8", caseId: nil)
            ])
        XCTAssertEqual(
            buckets[3].testEntries,
            [
                TestEntry(className: "class", methodName: "testMethod9", caseId: nil)
            ])
    }
}
