import Foundation
import Models
import SimulatorPool
import SimulatorPoolModels
import Types

public final class FakeCoreSimulatorStateProvider: CoreSimulatorStateProvider {
    public var result: Either<CoreSimulatorState?, Error>
    
    public init(result: Either<CoreSimulatorState?, Error> = .left(nil)) {
        self.result = result
    }
    
    public func coreSimulatorState(simulator: Simulator) throws -> CoreSimulatorState? {
        try result.dematerialize()
    }
}
