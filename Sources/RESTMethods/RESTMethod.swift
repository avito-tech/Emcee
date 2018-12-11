import Foundation

public enum RESTMethod: String {
    case registerWorker
    case getBucket
    case bucketResult
    case reportAlive
    case queueVersion
    
    public var withPrependingSlash: String {
        return "/\(self.rawValue)"
    }
}
