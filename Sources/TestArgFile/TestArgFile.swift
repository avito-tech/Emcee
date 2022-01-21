import EmceeExtensions
import Foundation
import LogStreamingModels
import MetricsExtensions
import QueueModels

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable, Equatable {
    
    /// Describes what tests to run and how to run them.
    public private(set) var entries: [TestArgFileEntry]
    
    /// Describes job priorities
    public let prioritizedJob: PrioritizedJob
    
    /// Per test destination output configuration
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    /// Defines what logs should be streamed back to client.
    public let logStreamingMode: ClientLogStreamingMode
    
    public init(
        entries: [TestArgFileEntry],
        prioritizedJob: PrioritizedJob,
        testDestinationConfigurations: [TestDestinationConfiguration],
        logStreamingMode: ClientLogStreamingMode
    ) {
        self.entries = entries
        self.prioritizedJob = prioritizedJob
        self.testDestinationConfigurations = testDestinationConfigurations
        self.logStreamingMode = logStreamingMode
    }
    
    public func with(entries: [TestArgFileEntry]) -> Self {
        var result = self
        result.entries = entries
        return result
    }
    
    private enum CodingKeys: String, CodingKey {
        case entries
        case prioritizedJob
        case testDestinationConfigurations
        
        case analyticsConfiguration
        case jobGroupId
        case jobGroupPriority
        case jobId
        case jobPriority
        case persistentMetricsJobId
        case logStreamingMode
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decodeExplaining([TestArgFileEntry].self, forKey: .entries)
        let logStreamingMode = try container.decodeIfPresentExplaining(ClientLogStreamingMode.self, forKey: .logStreamingMode) ?? TestArgFileDefaultValues.logStreamingMode
        
        let prioritizedJob = try container.decodeIfPresentExplaining(PrioritizedJob.self, forKey: .prioritizedJob) ?? { () -> PrioritizedJob in
            let jobId = try container.decodeIfPresentExplaining(JobId.self, forKey: .jobId) ?? TestArgFileDefaultValues.createAutomaticJobId()
            let jobPriority = try container.decodeIfPresentExplaining(Priority.self, forKey: .jobPriority) ?? TestArgFileDefaultValues.priority
            let jobGroupId = try container.decodeIfPresentExplaining(JobGroupId.self, forKey: .jobGroupId) ?? JobGroupId(jobId.value)
            let jobGroupPriority = try container.decodeIfPresentExplaining(Priority.self, forKey: .jobGroupPriority) ?? jobPriority
            let analyticsConfiguration = try container.decodeIfPresentExplaining(AnalyticsConfiguration.self, forKey: .analyticsConfiguration) ?? TestArgFileDefaultValues.analyticsConfiguration
            
            return PrioritizedJob(
                analyticsConfiguration: analyticsConfiguration,
                jobGroupId: jobGroupId,
                jobGroupPriority: jobGroupPriority,
                jobId: jobId,
                jobPriority: jobPriority
            )
        }()

        let testDestinationConfigurations = try container.decodeIfPresentExplaining([TestDestinationConfiguration].self, forKey: .testDestinationConfigurations) ?? []
    
        self.init(
            entries: entries,
            prioritizedJob: prioritizedJob,
            testDestinationConfigurations: testDestinationConfigurations,
            logStreamingMode: logStreamingMode
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entries, forKey: .entries)
        try container.encode(prioritizedJob, forKey: .prioritizedJob)
        try container.encode(testDestinationConfigurations, forKey: .testDestinationConfigurations)
    }
}
