import Foundation
import PathLib
import RunnerModels
import SimulatorPoolModels

public protocol SimulatorSetPathDeterminer {
    func simulatorSetPathSuitableForTestRunnerTool(
        simulatorLocation: SimulatorLocation
    ) throws -> AbsolutePath
}
