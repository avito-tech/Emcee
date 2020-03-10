import EmceeLib
import Foundation
import Models
import PathLib
import RunnerModels
import TestHelpers

public final class FakeSimulatorSetPathDeterminer: SimulatorSetPathDeterminer {
    public var provider: () throws -> AbsolutePath
    
    public init(provider: @escaping () throws -> AbsolutePath = { throw ErrorForTestingPurposes(text: "Error getting simulator set path for test tool") }) {
        self.provider = provider
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool() throws -> AbsolutePath {
        return try provider()
    }
}
