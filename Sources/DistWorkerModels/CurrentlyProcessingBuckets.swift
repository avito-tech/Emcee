import Foundation

public enum CurrentlyProcessingBuckets: String {
    case path = "currentlyProcessingBuckets"
    
    public var withLeadingSlash: String {
        return "/" + rawValue
    }
}
