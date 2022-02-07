import Foundation
import EmceeLoggingModels
import QueueModels

extension LogEntryCoordinate {
    public static var bucketIdCordinateName: String { "bucketId" }
    
    public static func bucketId(_ bucketId: BucketId) -> Self {
        Self(name: Self.bucketIdCordinateName, value: bucketId.value)
    }
}
