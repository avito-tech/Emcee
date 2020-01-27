import Foundation
import Models

public enum DistWorkerError: Error, CustomStringConvertible {
    case noRequestIdForBucketId(BucketId)
    case unexpectedAcceptedBucketId(actual: BucketId, expected: BucketId)
    case missingPayloadSignature
    
    public var description: String {
        switch self {
        case .noRequestIdForBucketId(let bucketId):
            return "No matching requestId found for bucket id: \(bucketId)."
        case .unexpectedAcceptedBucketId(let actual, let expected):
            return "Server said it accepted bucket with id '\(actual)', but testing result had bucket id '\(expected)'"
        case .missingPayloadSignature:
            return "Payload signature has not been obtained yet but is already required"
        }
    }
}
