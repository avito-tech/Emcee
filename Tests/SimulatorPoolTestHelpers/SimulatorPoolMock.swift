@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import PathLib
import TemporaryStuff

public final class SimulatorPoolMock: SimulatorPool {
    private let temporaryFolder: TemporaryFolder
    
    public init() throws {
        let temporaryFolder = try TemporaryFolder()
        self.temporaryFolder = temporaryFolder
        try super.init(
            developerDir: DeveloperDir.current,
            developerDirLocator: FakeDeveloperDirLocator(),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorControllerProvider: FakeSimulatorControllerProvider { testDestination in
                return FakeSimulatorController(
                    simulator: SimulatorFixture.simulator(),
                    simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                    developerDir: .current
                )
            },
            tempFolder: temporaryFolder,
            testDestination: TestDestinationFixtures.testDestination
        )
    }

    public var freedSimulator: SimulatorController?
    public override func freeSimulatorController(_ simulator: SimulatorController) {
        freedSimulator = simulator
    }
}
