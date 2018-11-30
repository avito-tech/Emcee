import Foundation

public struct LocalTestRunConfiguration {
    
    /** Various reports for the test run */
    public let reportOutput: ReportOutput
    
    /** Timeout values. */
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** Parameters that determinte how to execute the tests. */
    public let testRunExecutionBehavior: TestRunExecutionBehavior

    /** Paths that are required to make things work. */
    public let auxiliaryResources: AuxiliaryResources
    
    /** Some settings that should be applied to the test environment prior running the tests. */
    public let simulatorSettings: SimulatorSettings
    
    /** All tests that need to be run */
    public let testEntryConfigurations: [TestEntryConfiguration]
    
    public let testDestinationConfigurations: [TestDestinationConfiguration]
  
    public init(
        reportOutput: ReportOutput,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testRunExecutionBehavior: TestRunExecutionBehavior,
        auxiliaryResources: AuxiliaryResources,
        simulatorSettings: SimulatorSettings,
        testEntryConfigurations: [TestEntryConfiguration],
        testDestinationConfigurations: [TestDestinationConfiguration]) throws
    {
        self.reportOutput = reportOutput
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.auxiliaryResources = auxiliaryResources
        self.simulatorSettings = simulatorSettings
        self.testEntryConfigurations = testEntryConfigurations
        self.testDestinationConfigurations = testDestinationConfigurations
    }
}
