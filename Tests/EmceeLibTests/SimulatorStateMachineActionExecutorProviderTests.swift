@testable import SimulatorPool
import AppleTools
import EmceeLib
import Foundation
import ModelsTestHelpers
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest
import fbxctest

final class SimulatorStateMachineActionExecutorProviderTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private let fakeProcessControllerProvider = FakeProcessControllerProvider()
    private lazy var provider = SimulatorStateMachineActionExecutorProviderImpl(
        processControllerProvider: fakeProcessControllerProvider,
        resourceLocationResolver: FakeResourceLocationResolver.throwing(),
        simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { _ in self.tempFolder.absolutePath })
    )
    
    func test___simctl() {
        let executor = assertDoesNotThrow {
            try provider.simulatorStateMachineActionExecutor(
                simulatorControlTool: SimulatorControlTool(
                    location: .insideEmceeTempFolder,
                    tool: .simctl
                )
            )
        }
        let metricSupportingExecutor = assertIsMetricSupportingExecutor(executor: executor)
        XCTAssert(metricSupportingExecutor.delegate is SimctlBasedSimulatorStateMachineActionExecutor)
    }
    
    func test___fbsimctl() {
        let executor = assertDoesNotThrow {
            try provider.simulatorStateMachineActionExecutor(
                simulatorControlTool: SimulatorControlTool(
                    location: .insideEmceeTempFolder,
                    tool: .fbsimctl(FbsimcrlLocationFixtures.fakeFbsimctlLocation)
                )
            )
        }
        let metricSupportingExecutor = assertIsMetricSupportingExecutor(executor: executor)
        XCTAssert(metricSupportingExecutor.delegate is FbsimctlBasedSimulatorStateMachineActionExecutor)
    }
    
    private func assertIsMetricSupportingExecutor(
        executor: SimulatorStateMachineActionExecutor
    ) -> MetricSupportingSimulatorStateMachineActionExecutor {
        return withoutContinuingTestAfterFailure {
            XCTAssert(executor is MetricSupportingSimulatorStateMachineActionExecutor)
            return executor as! MetricSupportingSimulatorStateMachineActionExecutor
        }
    }
}
