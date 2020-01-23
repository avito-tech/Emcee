import EmceeLib
import Foundation
import ModelsTestHelpers
import ResourceLocationResolverTestHelpers
import TemporaryStuff
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class SimulatorSetPathDeterminerTests: XCTestCase {
    private let simulatorContainerFolder = "sims"
    private lazy var provider = SimulatorSetPathDeterminerImpl(
        simulatorContainerFolderName: simulatorContainerFolder,
        temporaryFolder: temporaryFolder,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private lazy var temporaryFolder: TemporaryFolder = assertDoesNotThrow {
        try TemporaryFolder()
    }
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    
    func test___simulator_set_path_is_default_one___when_xcodebuild_is_used___because_xcodebuild_only_works_with_default_simulator_set() {
        let path = assertDoesNotThrow {
            try provider.simulatorSetPathSuitableForTestRunnerTool(
                testRunnerTool: .xcodebuild
            )
        }
        XCTAssertEqual(
            path,
            SimulatorSetPathDeterminerPaths.defaultSimulatorSetPath
        )
    }
    
    func test___simulator_is_created_inside_temp_folder___when_fbxctest_is_used() {
        let path = assertDoesNotThrow {
            try provider.simulatorSetPathSuitableForTestRunnerTool(
                testRunnerTool: .fbxctest(FbxctestLocationFixtures.fakeFbxctestLocation)
            )
        }
        XCTAssertEqual(
            path,
            temporaryFolder.absolutePath.appending(components: [simulatorContainerFolder, uniqueIdentifierGenerator.value])
        )
    }
}
