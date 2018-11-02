import Foundation
import Models
import XCTest

final class ModelsTests: XCTestCase {
    let fakeToolResources = ToolResources(
        fbsimctl: .remoteUrl(URL(string: "http://example.com")!),
        fbxctest: .remoteUrl(URL(string: "http://example.com")!))
    
    func testBucketHasDetermenisticId() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            toolResources: fakeToolResources)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            toolResources: fakeToolResources)
        
        XCTAssertEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestEntries() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "-----", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            toolResources: fakeToolResources)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            toolResources: fakeToolResources)
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestDestinations() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            toolResources: fakeToolResources)
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.4"),
            toolResources: fakeToolResources)
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
}
