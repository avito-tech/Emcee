import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class BucketTests: XCTestCase {
    let fakeToolResources = ToolResourcesFixtures.fakeToolResources()
    let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    
    func testBucketHasDetermenisticId() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        XCTAssertEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestEntries() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "-----", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestDestinations() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", runtime: "11.3"),
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", runtime: "11.4"),
            toolResources: fakeToolResources,
            buildArtifacts: fakeBuildArtifacts)
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
}
