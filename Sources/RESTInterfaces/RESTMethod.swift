import Foundation

public enum RESTMethod: String, RESTPath {
    case bucketResult
    case disableWorker
    case enableWorker
    case getBucket
    case jobDelete
    case jobResults
    case jobState
    case queueVersion
    case registerWorker
    case reportAlive
    case scheduleTests
    case toggleWorkersSharing
    case workersToUtilize
    
    public var pathWithLeadingSlash: String {
        return "/\(self.rawValue)"
    }
}
