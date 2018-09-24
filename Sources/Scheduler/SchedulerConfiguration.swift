import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let auxiliaryPaths: AuxiliaryPaths
    public let testType: TestType
    public let buildArtifacts: BuildArtifacts
    public let testExecutionBehavior: TestExecutionBehavior
    public let simulatorSettings: SimulatorSettings
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testDiagnosticOutput: TestDiagnosticOutput
    public let schedulerDataSource: SchedulerDataSource
    public let onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    public let eventBus: EventBus
    
    public var runnerConfiguration: RunnerConfiguration {
        return RunnerConfiguration(
            testType: testType,
            fbxctest: auxiliaryPaths.fbxctest,
            buildArtifacts: buildArtifacts,
            testExecutionBehavior: testExecutionBehavior,
            simulatorSettings: simulatorSettings,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testDiagnosticOutput: testDiagnosticOutput)
    }

    public init(
        auxiliaryPaths: AuxiliaryPaths,
        testType: TestType,
        buildArtifacts: BuildArtifacts,
        testExecutionBehavior: TestExecutionBehavior,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testDiagnosticOutput: TestDiagnosticOutput,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        eventBus: EventBus)
    {
        self.auxiliaryPaths = auxiliaryPaths
        self.testType = testType
        self.buildArtifacts = buildArtifacts
        self.testExecutionBehavior = testExecutionBehavior
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testDiagnosticOutput = testDiagnosticOutput
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.eventBus = eventBus
    }
}
