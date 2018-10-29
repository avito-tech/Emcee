import Foundation
import Models
import RESTMethods

public enum BucketResultRequestError: Error, CustomStringConvertible {
    case noDequeuedBucket(requestId: String, workerId: String)
    case notAllResultsAvailable(requestId: String, workerId: String, expectedTestEntries: [TestEntry], providedResults: [TestEntryResult])
    
    public var description: String {
        switch self {
        case let .noDequeuedBucket(requestId, workerId):
            return "Cannot accept BucketResultRequest with requestId \(requestId) workerId \(workerId). This request does not have corresponding dequeued bucket."
        case let .notAllResultsAvailable(requestId, workerId, expectedTestEntries, providedResults):
            return "Not all results are in request \(requestId) from worker \(workerId): expected to have results for \(expectedTestEntries) test entries, provided results: \(providedResults)"
        }
    }
}
