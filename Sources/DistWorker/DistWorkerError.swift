import Foundation

public enum DistWorkerError: Error, CustomStringConvertible {
    case noRequestIdForBucketId(String)
    case unexpectedAcceptedBucketId(actual: String, expected: String)
    case missingRequestSignature
    
    public var description: String {
        switch self {
        case .noRequestIdForBucketId(let bucketId):
            return "No matching requestId found for bucket id: \(bucketId)."
        case .unexpectedAcceptedBucketId(let actual, let expected):
            return "Server said it accepted bucket with id '\(actual)', but testing result had bucket id '\(expected)'"
        case .missingRequestSignature:
            return "Request signature has not been obtained yet but is already required"
        }
    }
}
