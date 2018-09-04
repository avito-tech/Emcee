import Foundation

public enum DistWorkerError: Error, CustomStringConvertible {
    case noRequestIdForBucketId(String)
    
    public var description: String {
        switch self {
        case .noRequestIdForBucketId(let bucketId):
            return "No matching requestId found for bucket id: \(bucketId)."
        }
    }
}
