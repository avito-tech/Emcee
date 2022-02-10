import Foundation
import PathLib

public protocol SimulatorSetPathDeterminer {
    func simulatorSetPathSuitableForTestRunnerTool() throws -> AbsolutePath
}
