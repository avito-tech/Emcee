import Foundation

public enum RESTMethod: String {
    case bucketResult
    case getBucket
    case queueVersion
    case registerWorker
    case reportAlive
    case scheduleTests
    
    public var withPrependingSlash: String {
        return "/\(self.rawValue)"
    }
}
