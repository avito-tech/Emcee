@testable import SimulatorPool
@testable import ResourceLocationResolver
import Models
import TempFolder
import Basic

final class SimulatorPoolWithDefaultSimulatorControllerMock: SimulatorPool<DefaultSimulatorController> {
    private let testDestination: TestDestination
    private let fbsimctl: ResolvableResourceLocation

    init() throws {
        testDestination = try TestDestination(deviceType: "iPhoneXL", runtime: "10.3")
        fbsimctl = ResolvableResourceLocationImpl(
            resourceLocation: .localFilePath(""),
            resolver: ResourceLocationResolver()
        )
        let tempFolder = try TempFolder()


        try super.init(
            numberOfSimulators: 0,
            testDestination: testDestination,
            fbsimctl: fbsimctl,
            tempFolder: tempFolder)
    }

    override func allocateSimulatorController() throws -> DefaultSimulatorController {
        let simulator = Shimulator(index: 0, testDestination: testDestination, workingDirectory: AbsolutePath("/"))
        return DefaultSimulatorControllerMock(simulator: simulator, fbsimctl: fbsimctl)
    }
}
