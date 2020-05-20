import Foundation
import RESTInterfaces

public enum CurrentlyProcessingBuckets: String, RESTPath {
    case path = "currentlyProcessingBuckets"
    
    public var pathWithLeadingSlash: String {
        return "/" + rawValue
    }
}
