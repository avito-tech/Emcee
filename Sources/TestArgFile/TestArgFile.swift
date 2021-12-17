import Foundation
import LoggingSetup
import MetricsExtensions
import QueueModels

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable, Equatable {
    public private(set) var entries: [TestArgFileEntry]
    public let prioritizedJob: PrioritizedJob
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    public init(
        entries: [TestArgFileEntry],
        prioritizedJob: PrioritizedJob,
        testDestinationConfigurations: [TestDestinationConfiguration]
    ) {
        self.entries = entries
        self.prioritizedJob = prioritizedJob
        self.testDestinationConfigurations = testDestinationConfigurations
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
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let entries = try container.decode([TestArgFileEntry].self, forKey: .entries)
        
        let prioritizedJob = try container.decodeIfPresent(PrioritizedJob.self, forKey: .prioritizedJob) ?? { () -> PrioritizedJob in
            let jobId = try container.decodeIfPresent(JobId.self, forKey: .jobId) ??
                TestArgFileDefaultValues.createAutomaticJobId()
            let jobPriority = try container.decodeIfPresent(Priority.self, forKey: .jobPriority) ??
                TestArgFileDefaultValues.priority
            let jobGroupId = try container.decodeIfPresent(JobGroupId.self, forKey: .jobGroupId) ??
                JobGroupId(jobId.value)
            let jobGroupPriority = try container.decodeIfPresent(Priority.self, forKey: .jobGroupPriority) ??
                jobPriority
            let analyticsConfiguration = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfiguration) ??
                TestArgFileDefaultValues.analyticsConfiguration
            return PrioritizedJob(
                analyticsConfiguration: analyticsConfiguration,
                jobGroupId: jobGroupId,
                jobGroupPriority: jobGroupPriority,
                jobId: jobId,
                jobPriority: jobPriority
            )
        }()

        let testDestinationConfigurations = try container.decodeIfPresent([TestDestinationConfiguration].self, forKey: .testDestinationConfigurations) ??
            []
    
        self.init(
            entries: entries,
            prioritizedJob: prioritizedJob,
            testDestinationConfigurations: testDestinationConfigurations
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entries, forKey: .entries)
        try container.encode(prioritizedJob, forKey: .prioritizedJob)
        try container.encode(testDestinationConfigurations, forKey: .testDestinationConfigurations)
    }
}
