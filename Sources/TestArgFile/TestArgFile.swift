import Foundation
import LoggingSetup
import QueueModels

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable, Equatable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let entries: [TestArgFileEntry]
    public let prioritizedJob: PrioritizedJob
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        entries: [TestArgFileEntry],
        prioritizedJob: PrioritizedJob,
        testDestinationConfigurations: [TestDestinationConfiguration]
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.entries = entries
        self.prioritizedJob = prioritizedJob
        self.testDestinationConfigurations = testDestinationConfigurations
    }
    
    private enum CodingKeys: String, CodingKey {
        case analyticsConfiguration
        case entries
        case prioritizedJob
        case testDestinationConfigurations
        
        case jobGroupId
        case jobGroupPriority
        case jobId
        case jobPriority
        case persistentMetricsJobId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let analyticsConfiguration = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfiguration) ??
            TestArgFileDefaultValues.analyticsConfiguration
        
        let entries = try container.decode([TestArgFileEntry].self, forKey: .entries)
        
        let prioritizedJob = try container.decodeIfPresent(PrioritizedJob.self, forKey: .prioritizedJob) ?? { () -> PrioritizedJob in
            let jobId = try container.decode(JobId.self, forKey: .jobId)
            let jobPriority = try container.decodeIfPresent(Priority.self, forKey: .jobPriority) ??
                TestArgFileDefaultValues.priority
            let jobGroupId = try container.decodeIfPresent(JobGroupId.self, forKey: .jobGroupId) ??
                JobGroupId(jobId.value)
            let jobGroupPriority = try container.decodeIfPresent(Priority.self, forKey: .jobGroupPriority) ??
                jobPriority
            let persistentMetricsJobId = try container.decodeIfPresent(String.self, forKey: .persistentMetricsJobId) ??
                TestArgFileDefaultValues.persistentMetricsJobId
            return PrioritizedJob(
                jobGroupId: jobGroupId,
                jobGroupPriority: jobGroupPriority,
                jobId: jobId,
                jobPriority: jobPriority,
                persistentMetricsJobId: persistentMetricsJobId
            )
        }()

        let testDestinationConfigurations = try container.decodeIfPresent([TestDestinationConfiguration].self, forKey: .testDestinationConfigurations) ??
            []
    
        self.init(
            analyticsConfiguration: analyticsConfiguration,
            entries: entries,
            prioritizedJob: prioritizedJob,
            testDestinationConfigurations: testDestinationConfigurations
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(analyticsConfiguration, forKey: .analyticsConfiguration)
        try container.encode(entries, forKey: .entries)
        try container.encode(prioritizedJob, forKey: .prioritizedJob)
        try container.encode(testDestinationConfigurations, forKey: .testDestinationConfigurations)
    }
}
