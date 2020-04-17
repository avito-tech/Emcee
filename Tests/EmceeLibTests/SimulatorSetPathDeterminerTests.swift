import EmceeLib
import FileSystem
import FileSystemTestHelpers
import Foundation
import ModelsTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolModels
import TemporaryStuff
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class SimulatorSetPathDeterminerTests: XCTestCase {
    private let simulatorContainerFolder = "sims"
    private lazy var fileSystem = FakeFileSystem(
        rootPath: temporaryFolder.absolutePath
    )
    private lazy var provider = SimulatorSetPathDeterminerImpl(
        fileSystem: fileSystem,
        simulatorContainerFolderName: simulatorContainerFolder,
        temporaryFolder: temporaryFolder,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private lazy var temporaryFolder: TemporaryFolder = assertDoesNotThrow {
        try TemporaryFolder()
    }
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    
    func test___simulator_path_is_inside_temp_folder() {
        let path = assertDoesNotThrow {
            try provider.simulatorSetPathSuitableForTestRunnerTool(
                simulatorLocation: .insideEmceeTempFolder
            )
        }
        XCTAssertEqual(
            path,
            temporaryFolder.absolutePath.appending(components: [simulatorContainerFolder, uniqueIdentifierGenerator.value])
        )
    }
    
    func test___simulator_path_is_inside_system_folder() {
        let path = assertDoesNotThrow {
            try provider.simulatorSetPathSuitableForTestRunnerTool(
                simulatorLocation: .insideUserLibrary
            )
        }
        XCTAssertEqual(
            path,
            try fileSystem.commonlyUsedPathsProvider.library(inDomain: .user, create: false).appending(
                components: ["Developer", "CoreSimulator", "Devices"]
            )
        )
    }
}
