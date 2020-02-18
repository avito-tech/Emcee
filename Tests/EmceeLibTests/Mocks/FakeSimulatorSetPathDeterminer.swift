import EmceeLib
import Foundation
import Models
import PathLib
import RunnerModels
import TestHelpers

public final class FakeSimulatorSetPathDeterminer: SimulatorSetPathDeterminer {
    public var provider: (TestRunnerTool) throws -> AbsolutePath
    
    public init(provider: @escaping (TestRunnerTool) throws -> AbsolutePath = { throw ErrorForTestingPurposes(text: "Error getting simulator set path for test tool \($0)") }) {
        self.provider = provider
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool(testRunnerTool: TestRunnerTool) throws -> AbsolutePath {
        return try provider(testRunnerTool)
    }
}
