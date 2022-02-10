import Foundation
import MetricsExtensions
import WorkerCapabilitiesModels

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let testConfigurationContainer: TestConfigurationContainer
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        testConfigurationContainer: TestConfigurationContainer,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.testConfigurationContainer = testConfigurationContainer
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testConfigurationContainer) \(analyticsConfiguration) \(workerCapabilityRequirements)>"
    }
}
