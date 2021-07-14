import FileSystem
import Foundation
import PathLib
import RunnerModels
import SimulatorPoolModels
import Tmp
import UniqueIdentifierGenerator

public final class SimulatorSetPathDeterminerImpl: SimulatorSetPathDeterminer {
    private let fileSystem: FileSystem
    private let simulatorContainerFolderName: String
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        fileSystem: FileSystem,
        simulatorContainerFolderName: String = "simulators",
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.fileSystem = fileSystem
        self.simulatorContainerFolderName = simulatorContainerFolderName
        self.temporaryFolder = temporaryFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool(
        simulatorLocation: SimulatorLocation
    ) throws -> AbsolutePath {
        switch simulatorLocation {
        case .insideEmceeTempFolder:
            return try temporaryFolder.pathByCreatingDirectories(
                components: [simulatorContainerFolderName, uniqueIdentifierGenerator.generate()]
            )
        case .insideUserLibrary:
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
}
