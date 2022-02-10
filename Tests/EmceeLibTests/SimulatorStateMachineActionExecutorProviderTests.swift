@testable import SimulatorPool
import AppleTools
import DateProviderTestHelpers
import EmceeLib
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import ProcessControllerTestHelpers
import QueueModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import Tmp
import XCTest

final class SimulatorStateMachineActionExecutorProviderTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var fakeProcessControllerProvider = FakeProcessControllerProvider()
    private lazy var provider = SimulatorStateMachineActionExecutorProviderImpl(
        dateProvider: DateProviderFixture(),
        processControllerProvider: fakeProcessControllerProvider,
        simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(
            provider: { self.tempFolder.absolutePath }
        ),
        version: Version(value: "version"),
        globalMetricRecorder: GlobalMetricRecorderImpl()
    )
    
    func test___simctl() {
        let executor = assertDoesNotThrow {
            try provider.simulatorStateMachineActionExecutor()
        }
        let metricSupportingExecutor = assertIsMetricSupportingExecutor(executor: executor)
        XCTAssert(metricSupportingExecutor.delegate is SimctlBasedSimulatorStateMachineActionExecutor)
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
