import Foundation

public enum RESTMethod: String {
    case registerWorker
    case getBucket
    case bucketResult
    case reportAlive
    
    public var withPrependingSlash: String {
        return "/\(self.rawValue)"
    }
}
