@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import PathLib
import TemporaryStuff

public final class SimulatorPoolMock: SimulatorPool {
    public static let simulatorController = FakeSimulatorController(
        simulator: Shimulator(
            testDestination: TestDestinationFixtures.testDestination,
            workingDirectory: .root
        ),
        simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
        developerDir: .current
    )
    
    public init() throws {
        try super.init(
            developerDir: DeveloperDir.current,
            developerDirLocator: FakeDeveloperDirLocator(),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorControllerProvider: FakeSimulatorControllerProvider { _ in
                return SimulatorPoolMock.simulatorController
            },
            tempFolder: try TemporaryFolder(),
            testDestination: TestDestinationFixtures.testDestination
        )
    }

    public var freedSimulator: SimulatorController?
    public override func freeSimulatorController(_ simulator: SimulatorController) {
        freedSimulator = simulator
    }
}
