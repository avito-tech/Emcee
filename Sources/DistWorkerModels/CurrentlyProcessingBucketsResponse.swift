import Foundation
import Models

public struct CurrentlyProcessingBucketsResponse: Codable {
    public let bucketIds: [BucketId]

    public init(bucketIds: [BucketId]) {
        self.bucketIds = bucketIds
    }
}
