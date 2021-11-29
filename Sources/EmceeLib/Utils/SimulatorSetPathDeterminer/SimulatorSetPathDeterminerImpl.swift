import FileSystem
import Foundation
import PathLib

public final class SimulatorSetPathDeterminerImpl: SimulatorSetPathDeterminer {
    private let fileSystem: FileSystem

    public init(
        fileSystem: FileSystem
    ) {
        self.fileSystem = fileSystem
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool() throws -> AbsolutePath {
        let path = try fileSystem.userLibraryPath().appending(
            relativePath: "Developer/CoreSimulator/Devices"
        )
        try fileSystem.createDirectory(
            atPath: path,
            withIntermediateDirectories: true
        )
        return path
    }
}
