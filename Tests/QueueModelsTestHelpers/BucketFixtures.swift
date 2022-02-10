import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import Foundation
import MetricsExtensions
import QueueModels
import SimulatorPoolTestHelpers
import WorkerCapabilitiesModels

public final class BucketFixtures {
    public var bucketId: BucketId
    public var analyticsConfiguration: AnalyticsConfiguration
    public var workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    public var payloadContainer: BucketPayloadContainer
    
    public init(
        bucketId: BucketId = BucketId(value: "BucketFixturesFixedBucketId"),
        analyticsConfiguration: AnalyticsConfiguration = AnalyticsConfiguration(),
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = [],
        payloadContainer: BucketPayloadContainer? = nil
    ) {
        self.bucketId = bucketId
        self.analyticsConfiguration = analyticsConfiguration
        self.workerCapabilityRequirements = workerCapabilityRequirements
        self.payloadContainer = payloadContainer ?? .runAppleTests(
            RunAppleTestsPayloadFixture().runAppleTestsPayload()
        )
    }
    
    public func with(bucketId: BucketId) -> Self {
        self.bucketId = bucketId
        return self
    }
    
    public func with(analyticsConfiguration: AnalyticsConfiguration) -> Self {
        self.analyticsConfiguration = analyticsConfiguration
        return self
    }
    
    public func with(workerCapabilityRequirements: Set<WorkerCapabilityRequirement>) -> Self {
        self.workerCapabilityRequirements = workerCapabilityRequirements
        return self
    }
    
    public func with(payloadContainer: BucketPayloadContainer) -> Self {
        self.payloadContainer = payloadContainer
        return self
    }
    
    public func with(runAppleTestsPayload: RunAppleTestsPayload) -> Self {
        with(payloadContainer: .runAppleTests(runAppleTestsPayload))
    }
    
    public func with(runAndroidTestsPayload: RunAndroidTestsPayload) -> Self {
        with(payloadContainer: .runAndroidTests(runAndroidTestsPayload))
    }
    
    public func bucket() -> Bucket {
        Bucket.newBucket(
            bucketId: bucketId,
            analyticsConfiguration: analyticsConfiguration,
            workerCapabilityRequirements: workerCapabilityRequirements,
            payloadContainer: payloadContainer
        )
    }
}
