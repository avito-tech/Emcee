import AppleTools
import EmceeLib
import Foundation
import ModelsTestHelpers
import ResourceLocationResolverTestHelpers
import TemporaryStuff
import XCTest
import fbxctest

final class SimulatorStateMachineActionExecutorProviderTests: XCTestCase {
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    func test___simctl() {
        let provider = SimulatorStateMachineActionExecutorProviderImpl(
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
