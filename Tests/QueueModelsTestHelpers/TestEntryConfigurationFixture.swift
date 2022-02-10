import AndroidTestModels
import AppleTestModels
import AppleTestModelsTestHelpers
import MetricsExtensions
import QueueModels
import WorkerCapabilitiesModels

public final class TestEntryConfigurationFixtures {
    public var analyticsConfiguration: AnalyticsConfiguration
    public var testConfigurationContainer: TestConfigurationContainer
    public var workerCapabilityRequirements: Set<WorkerCapabilityRequirement>

    public init(
        analyticsConfiguration: AnalyticsConfiguration = AnalyticsConfiguration(),
        testConfigurationContainer: TestConfigurationContainer = .appleTest(AppleTestConfigurationFixture().appleTestConfiguration()),
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = []
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.testConfigurationContainer = testConfigurationContainer
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public func with(analyticsConfiguration: AnalyticsConfiguration) -> Self {
        self.analyticsConfiguration = analyticsConfiguration
        return self
    }
    
    public func with(testConfigurationContainer: TestConfigurationContainer) -> Self {
        self.testConfigurationContainer = testConfigurationContainer
        return self
    }
    
    public func with(workerCapabilityRequirements: Set<WorkerCapabilityRequirement>) -> Self {
        self.workerCapabilityRequirements = workerCapabilityRequirements
        return self
    }
    
    public func with(appleTestConfiguration: AppleTestConfiguration) -> Self {
        return with(testConfigurationContainer: .appleTest(appleTestConfiguration))
    }
    
    public func with(androidTestConfiguration: AndroidTestConfiguration) -> Self {
        return with(testConfigurationContainer: .androidTest(androidTestConfiguration))
    }
    
    public func testEntryConfiguration() -> TestEntryConfiguration {
        TestEntryConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            testConfigurationContainer: testConfigurationContainer,
            workerCapabilityRequirements: workerCapabilityRequirements
        )
    }
    
    public convenience init(
        analyticsConfiguration: AnalyticsConfiguration,
        appleTestConfiguration: AppleTestConfiguration,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.init(
            analyticsConfiguration: analyticsConfiguration,
            testConfigurationContainer: .appleTest(appleTestConfiguration),
            workerCapabilityRequirements: workerCapabilityRequirements
        )
    }
    
    public convenience init(
        analyticsConfiguration: AnalyticsConfiguration,
        androidTestConfiguration: AndroidTestConfiguration,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.init(
            analyticsConfiguration: analyticsConfiguration,
            testConfigurationContainer: .androidTest(androidTestConfiguration),
            workerCapabilityRequirements: workerCapabilityRequirements
        )
    }

}
