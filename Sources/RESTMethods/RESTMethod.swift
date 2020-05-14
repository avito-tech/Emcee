import Foundation

public enum RESTMethod: String {
    case bucketResult
    case getBucket
    case queueVersion
    case registerWorker
    case reportAlive
    case scheduleTests
    case jobState
    case jobResults
    case jobDelete
    case disableWorker
    
    public var withLeadingSlash: String {
        return "/\(self.rawValue)"
    }
}
