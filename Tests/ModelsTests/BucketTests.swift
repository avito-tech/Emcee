import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class BucketTests: XCTestCase {
    let fakeToolResources = ToolResourcesFixtures.fakeToolResources()
    let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    let fakeSimulatorSettings = SimulatorSettingsFixtures().simulatorSettings()
    let testType = TestType.uiTest
    
    func testBucketEquality() throws {
        let bucketId = BucketId(value: UUID().uuidString)
        let bucket1 = Bucket(
            bucketId: bucketId,
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        let bucket2 = Bucket(
            bucketId: bucketId,
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        XCTAssertEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestEntries() throws {
        let bucket1 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "-----", methodName: "testMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        let bucket2 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestDestinations() throws {
        let bucket1 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: try TestDestination(deviceType: "device", runtime: "11.3"),
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        let bucket2 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod"),
                TestEntryFixtures.testEntry(className: "class", methodName: "testAnotherMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: try TestDestination(deviceType: "device", runtime: "11.4"),
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentEnvironments() throws {
        let bucket1 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a":"1"]).build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        let bucket2 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures(environment: ["a":"2"]).build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        XCTAssertNotEqual(
            bucket1.bucketId,
            bucket2.bucketId
        )
    }
    
    func testBucketsHaveDifferentIdsForDifferentNumberOfRetries() throws {
        let bucket1 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures(numberOfRetries: 0).build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        let bucket2 = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [
                TestEntryFixtures.testEntry(className: "class", methodName: "testMethod")
            ],
            buildArtifacts: fakeBuildArtifacts,
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures(numberOfRetries: 1).build(),
            toolResources: fakeToolResources,
            testType: testType
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    // todo add test
}
