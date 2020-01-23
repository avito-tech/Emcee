import Foundation
import Models
import PathLib

public protocol SimulatorSetPathDeterminer {
    func simulatorSetPathSuitableForTestRunnerTool(
        testRunnerTool: TestRunnerTool
    ) throws -> AbsolutePath
}

public enum SimulatorSetPathDeterminerPaths {
    public static let defaultSimulatorSetPath = AbsolutePath.home.appending(
        relativePath: RelativePath("Library/Developer/CoreSimulator/Devices")
    )
}
