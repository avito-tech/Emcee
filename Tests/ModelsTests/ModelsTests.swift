import Foundation
import Models
import XCTest

final class ModelsTests: XCTestCase {
    func testBucketHasDetermenisticId() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"))
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"))
        
        XCTAssertEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestEntries() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "-----", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"))
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"))
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
    
    func testBucketsHaveDifferentIdsForDifferentTestDestinations() throws {
        let bucket1 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"))
        
        let bucket2 = Bucket(
            testEntries: [
                TestEntry(className: "class", methodName: "testMethod", caseId: nil),
                TestEntry(className: "class", methodName: "testAnotherMethod", caseId: nil)
            ],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.4"))
        
        XCTAssertNotEqual(bucket1.bucketId, bucket2.bucketId)
    }
}
