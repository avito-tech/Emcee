import Foundation

public enum CurrentlyProcessingBuckets: String {
    case path = "currentlyProcessingBuckets"
    
    public var withPrependedSlash: String {
        return rawValue + "/"
    }
}
