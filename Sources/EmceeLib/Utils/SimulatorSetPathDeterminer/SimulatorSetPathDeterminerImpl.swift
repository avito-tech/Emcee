import FileSystem
import Foundation
import Models
import PathLib
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class SimulatorSetPathDeterminerImpl: SimulatorSetPathDeterminer {
    private let fileSystem: FileSystem
    private let simulatorContainerFolderName: String
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        fileSystem: FileSystem,
        simulatorContainerFolderName: String = "fbsimctl_simulators",
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
            return try fileSystem.commonlyUsedPathsProvider.library(inDomain: .user, create: true).appending(
                relativePath: RelativePath("Developer/CoreSimulator/Devices")
            )
        }

    }
}
