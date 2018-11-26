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
    
    /** A set of paths to the build artifacts */
    public let buildArtifacts: BuildArtifacts
    
    /** Some settings that should be applied to the test environment prior running the tests. */
    public let simulatorSettings: SimulatorSettings
    
    /** Test destination configurations */
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    /** All tests that need to be run */
    public let testEntries: [TestEntry]
  
    public init(
        reportOutput: ReportOutput,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testRunExecutionBehavior: TestRunExecutionBehavior,
        auxiliaryResources: AuxiliaryResources,
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings,
        testDestinationConfigurations: [TestDestinationConfiguration],
        testEntries: [TestEntry]) throws
    {
        self.reportOutput = reportOutput
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.auxiliaryResources = auxiliaryResources
        self.buildArtifacts = buildArtifacts
        self.simulatorSettings = simulatorSettings
        self.testDestinationConfigurations = testDestinationConfigurations
        self.testEntries = testEntries
    }
    
    public var testDestinations: [TestDestination] {
        return testDestinationConfigurations.map { $0.testDestination }
    }
}
