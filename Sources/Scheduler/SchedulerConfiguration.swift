import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let toolResources: ToolResources
    public let testType: TestType
    public let buildArtifacts: BuildArtifacts
    public let testExecutionBehavior: TestExecutionBehavior
    public let simulatorSettings: SimulatorSettings
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testDiagnosticOutput: TestDiagnosticOutput
    public let schedulerDataSource: SchedulerDataSource
    public let onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    
    public var runnerConfiguration: RunnerConfiguration {
        return RunnerConfiguration(
            testType: testType,
            fbxctest: toolResources.fbxctest,
            buildArtifacts: buildArtifacts,
            testExecutionBehavior: testExecutionBehavior,
            simulatorSettings: simulatorSettings,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testDiagnosticOutput: testDiagnosticOutput)
    }

    public init(
        toolResources: ToolResources,
        testType: TestType,
        buildArtifacts: BuildArtifacts,
        testExecutionBehavior: TestExecutionBehavior,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testDiagnosticOutput: TestDiagnosticOutput,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>)
    {
        self.toolResources = toolResources
        self.testType = testType
        self.buildArtifacts = buildArtifacts
        self.testExecutionBehavior = testExecutionBehavior
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testDiagnosticOutput = testDiagnosticOutput
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
    }
}
