import EmceeLib
import Foundation
import ModelsTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
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
    
    func test___simulator_is_created_inside_temp_folder() {
        let path = assertDoesNotThrow {
            try provider.simulatorSetPathSuitableForTestRunnerTool()
        }
        XCTAssertEqual(
            path,
            temporaryFolder.absolutePath.appending(components: [simulatorContainerFolder, uniqueIdentifierGenerator.value])
        )
    }
}
