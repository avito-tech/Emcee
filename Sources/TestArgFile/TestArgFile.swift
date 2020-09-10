import Foundation
import QueueModels

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable, Equatable {
    public let entries: [TestArgFileEntry]
    public let jobGroupId: JobGroupId
    public let jobGroupPriority: Priority
    public let jobId: JobId
    public let jobPriority: Priority
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    public let persistentMetricsJobId: String
    
    public init(
        entries: [TestArgFileEntry],
        jobGroupId: JobGroupId,
        jobGroupPriority: Priority,
        jobId: JobId,
        jobPriority: Priority,
        testDestinationConfigurations: [TestDestinationConfiguration],
        persistentMetricsJobId: String
    ) {
        self.entries = entries
        self.jobGroupId = jobGroupId
        self.jobGroupPriority = jobGroupPriority
        self.jobId = jobId
        self.jobPriority = jobPriority
        self.testDestinationConfigurations = testDestinationConfigurations
        self.persistentMetricsJobId = persistentMetricsJobId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entries = try container.decode([TestArgFileEntry].self, forKey: .entries)
        let jobId = try container.decode(JobId.self, forKey: .jobId)
        
        let jobPriority = try container.decodeIfPresent(Priority.self, forKey: .jobPriority) ??
            TestArgFileDefaultValues.priority
        let jobGroupId = try container.decodeIfPresent(JobGroupId.self, forKey: .jobGroupId) ??
            JobGroupId(jobId.value)
        let jobGroupPriority = try container.decodeIfPresent(Priority.self, forKey: .jobGroupPriority) ??
            jobPriority
        let testDestinationConfigurations = try container.decodeIfPresent([TestDestinationConfiguration].self, forKey: .testDestinationConfigurations) ??
            []
        let persistentMetricsJobId = try container.decodeIfPresent(String.self, forKey: .persistentMetricsJobId) ?? TestArgFileDefaultValues.persistentMetricsJobId
        
        self.init(
            entries: entries,
            jobGroupId: jobGroupId,
            jobGroupPriority: jobGroupPriority,
            jobId: jobId,
            jobPriority: jobPriority,
            testDestinationConfigurations: testDestinationConfigurations,
            persistentMetricsJobId: persistentMetricsJobId
        )
    }
}
