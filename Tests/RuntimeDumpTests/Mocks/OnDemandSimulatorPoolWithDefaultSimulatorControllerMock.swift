@testable import SimulatorPool
import ResourceLocationResolver
import TemporaryStuff

final class OnDemandSimulatorPoolWithDefaultSimulatorControllerMock: OnDemandSimulatorPool<DefaultSimulatorController> {

    convenience init() throws {
        let resourceLocationResolver = ResourceLocationResolver()
        let tempFolder = try TemporaryFolder()

        self.init(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
    }

    var poolMethodCalled = false
    override func pool(key: OnDemandSimulatorPool<DefaultSimulatorController>.Key) throws -> SimulatorPool<DefaultSimulatorController> {
        poolMethodCalled = true
        return try SimulatorPoolWithDefaultSimulatorControllerMock()
    }

    override func deleteSimulators() {

    }
}
