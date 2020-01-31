import AppleTools
import EmceeLib
import Foundation
import ModelsTestHelpers
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
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
            simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { _ in self.tempFolder.absolutePath })
        )
        
        assertDoesNotThrow {
            let executor = try provider.simulatorStateMachineActionExecutor(
                simulatorControlTool: .simctl,
                testRunnerTool: .xcodebuild
            )
            XCTAssert(executor is SimctlBasedSimulatorStateMachineActionExecutor)
        }
    }
    
    func test___fbsimctl() {
        let provider = SimulatorStateMachineActionExecutorProviderImpl(
            processControllerProvider: fakeProcessControllerProvider,
            resourceLocationResolver: FakeResourceLocationResolver.throwing(),
            simulatorSetPathDeterminer: FakeSimulatorSetPathDeterminer(provider: { _ in self.tempFolder.absolutePath })
        )
        
        assertDoesNotThrow {
            let executor = try provider.simulatorStateMachineActionExecutor(
                simulatorControlTool: .fbsimctl(FbsimcrlLocationFixtures.fakeFbsimctlLocation),
                testRunnerTool: .xcodebuild
            )
            XCTAssert(executor is FbsimctlBasedSimulatorStateMachineActionExecutor)
        }
    }
}
