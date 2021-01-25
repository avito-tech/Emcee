@testable import SimulatorPool
import AppleTools
import DateProviderTestHelpers
import EmceeLib
import Foundation
import MetricsTestHelpers
import ProcessControllerTestHelpers
import QueueModels
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import Tmp
import XCTest
import fbxctest

final class SimulatorStateMachineActionExecutorProviderTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var fakeProcessControllerProvider = FakeProcessControllerProvider()
    private lazy var provider = SimulatorStateMachineActionExecutorProviderImpl(
        dateProvider: DateProviderFixture(),
        processControllerProvider: fakeProcessControllerProvider,
        resourceLocationResolver: FakeResourceLocationResolver.throwing(),
        simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { _ in self.tempFolder.absolutePath }),
        version: Version(value: "version"),
        metricRecorder: NoOpMetricRecorder()
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
