@testable import SimulatorPool
import Models
import ModelsTestHelpers
import PathLib
import TemporaryStuff

public final class SimulatorPoolMock: SimulatorPool {
    public static let simulatorController = FakeSimulatorController(
        simulator: Shimulator(
            index: 0,
            testDestination: TestDestinationFixtures.testDestination,
            workingDirectory: .root
        ),
        simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
        developerDir: .current
    )
    
    public init() throws {
        try super.init(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: DeveloperDir.current,
            simulatorControllerProvider: FakeSimulatorControllerProvider { _ in
                return SimulatorPoolMock.simulatorController
            },
            tempFolder: try TemporaryFolder()
        )
    }

    public var freedSimulator: SimulatorController?
    public override func freeSimulatorController(_ simulator: SimulatorController) {
        freedSimulator = simulator
    }
}
