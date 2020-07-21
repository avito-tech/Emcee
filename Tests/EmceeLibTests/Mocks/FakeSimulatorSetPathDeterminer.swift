import EmceeLib
import Foundation
import PathLib
import RunnerModels
import SimulatorPoolModels
import TestHelpers

public final class FakeSimulatorSetPathDeterminer: SimulatorSetPathDeterminer {
    public var provider: (SimulatorLocation) throws -> AbsolutePath
    
    public init(provider: @escaping (SimulatorLocation) throws -> AbsolutePath = { throw ErrorForTestingPurposes(text: "Error getting simulator set path for test tool with location \($0)") }) {
        self.provider = provider
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool(
        simulatorLocation: SimulatorLocation
    ) throws -> AbsolutePath {
        return try provider(simulatorLocation)
    }
}
