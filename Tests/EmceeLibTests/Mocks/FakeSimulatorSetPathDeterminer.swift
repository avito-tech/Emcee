import EmceeLib
import Foundation
import PathLib
import SimulatorPoolModels
import TestHelpers

public final class FakeSimulatorSetPathDeterminer: SimulatorSetPathDeterminer {
    public var provider: () throws -> AbsolutePath
    
    public init(
        provider: @escaping () throws -> AbsolutePath = {
            throw ErrorForTestingPurposes(text: "Error getting simulator set path for testing")
        }
    ) {
        self.provider = provider
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool() throws -> AbsolutePath {
        return try provider()
    }
}
