import Foundation

public struct BucketResult: Codable, CustomStringConvertible {
    public let testingResult: TestingResult
    
    public init(testingResult: TestingResult) {
        self.testingResult = testingResult
    }
    
    public var description: String {
        let successCount = testingResult.successfulTests.count
        let failedCount = testingResult.failedTests.count
        return "<\(type(of: self)) \(testingResult.bucket.bucketId) \(successCount) successful tests, \(failedCount) failed tests>"
    }
}
