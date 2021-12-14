
import Foundation
import MetricsExtensions
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import WorkerCapabilitiesModels

public struct Bucket: Codable, Hashable, CustomStringConvertible {
    public private(set) var bucketId: BucketId
    public let analyticsConfiguration: AnalyticsConfiguration
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    public private(set) var payload: BucketPayload

    private init(
        bucketId: BucketId,
        analyticsConfiguration: AnalyticsConfiguration,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>,
        payload: BucketPayload
    ) {
        self.bucketId = bucketId
        self.analyticsConfiguration = analyticsConfiguration
        self.workerCapabilityRequirements = workerCapabilityRequirements
        self.payload = payload
    }
    
    public var description: String {
        return "<\((type(of: self))) \(bucketId) payload: \(payload)>"
    }

    /// Explicit method to make it clear that you usually should not create new bucket directly.
    public static func newBucket(
        bucketId: BucketId,
        analyticsConfiguration: AnalyticsConfiguration,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>,
        payload: BucketPayload
    ) -> Bucket {
        return Bucket(
            bucketId: bucketId,
            analyticsConfiguration: analyticsConfiguration,
            workerCapabilityRequirements: workerCapabilityRequirements,
            payload: payload
        )
    }

    public struct RepeatedBucketIdError: Error, CustomStringConvertible {
        let matchingId: BucketId
        public var description: String {
            "New bucket has id (\(matchingId)) which is equal to the previous bucket id. No two buckets with the same IDs should exist."
        }
    }
    
    public func with(newBucketId: BucketId) throws -> Bucket {
        guard newBucketId != bucketId else {
            throw RepeatedBucketIdError(matchingId: bucketId)
        }
        var bucket = self
        bucket.bucketId = newBucketId
        return bucket
    }

    /// Changing any property of bucket usually means you need a new bucket id.
    /// This method will throw error if previous bucket id matches new bucket id.
    public func with(
        newBucketId: BucketId,
        newPayload: BucketPayload
    ) throws -> Bucket {
        var bucket = try with(newBucketId: newBucketId)
        bucket.payload = newPayload
        return bucket
    }
}
