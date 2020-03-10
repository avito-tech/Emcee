import AppleTools
import EmceeLib
import Foundation
import ModelsTestHelpers
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest
import fbxctest

final class SimulatorStateMachineActionExecutorProviderTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private let fakeProcessControllerProvider = FakeProcessControllerProvider()
    
    func test___simctl() {
        let provider = SimulatorStateMachineActionExecutorProviderImpl(
            processControllerProvider: fakeProcessControllerProvider,
            resourceLocationResolver: FakeResourceLocationResolver.throwing(),
            simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { self.tempFolder.absolutePath })
        )
        
        assertDoesNotThrow {
            let executor = try provider.simulatorStateMachineActionExecutor(simulatorControlTool: .simctl)
            XCTAssert(executor is SimctlBasedSimulatorStateMachineActionExecutor)
        }
    }
    
    func test___fbsimctl() {
        let provider = SimulatorStateMachineActionExecutorProviderImpl(
            processControllerProvider: fakeProcessControllerProvider,
            resourceLocationResolver: FakeResourceLocationResolver.throwing(),
            simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { self.tempFolder.absolutePath })
        )
        
        assertDoesNotThrow {
            let executor = try provider.simulatorStateMachineActionExecutor(
                simulatorControlTool: .fbsimctl(FbsimcrlLocationFixtures.fakeFbsimctlLocation)
            )
            XCTAssert(executor is FbsimctlBasedSimulatorStateMachineActionExecutor)
        }
    }
}
