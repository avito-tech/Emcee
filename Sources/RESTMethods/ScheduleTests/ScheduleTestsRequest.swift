import Foundation
import Models

public final class ScheduleTestsRequest: Codable {
    public let requestId: String
    public let jobId: JobId
    public let testEntryConfigurations: [TestEntryConfiguration]

    public init(
        requestId: String,
        jobId: JobId,
        testEntryConfigurations: [TestEntryConfiguration])
    {
        self.requestId = requestId
        self.jobId = jobId
        self.testEntryConfigurations = testEntryConfigurations
    }
    
}
