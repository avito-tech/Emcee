import Foundation
import Models
import QueueModels

public struct CurrentlyProcessingBucketsResponse: Codable {
    public let bucketIds: [BucketId]

    public init(bucketIds: [BucketId]) {
        self.bucketIds = bucketIds
    }
}
