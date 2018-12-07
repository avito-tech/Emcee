import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class BucketTests: XCTestCase {
    let fakeToolResources = ToolResourcesFixtures.fakeToolResources()
    let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    let fakeSimulatorSettings = SimulatorSettingsFixtures().simulatorSettings()
    
    func testBucketHasDetermenisticId() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        XCTAssertEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestEntries() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "-----", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestDestinations() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: try TestDestination(deviceType: "device", runtime: "11.3"),
            toolResources: fakeToolResources
        )
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: [:],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: try TestDestination(deviceType: "device", runtime: "11.4"),
            toolResources: fakeToolResources
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentEnvironments() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: ["a":"1"],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            buildArtifacts: fakeBuildArtifacts,
            environment: ["a":"2"],
            simulatorSettings: fakeSimulatorSettings,
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources
        )
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
}
