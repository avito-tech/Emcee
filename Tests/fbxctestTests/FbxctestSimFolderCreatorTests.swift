import Foundation
import Models
import ModelsTestHelpers
import TemporaryStuff
import TestHelpers
import XCTest
import fbxctest

final class FbxctestSimFolderCreatorTests: XCTestCase {
    private let creator = FbxctestSimFolderCreator()
    private let udid = UDID(value: UUID().uuidString)
    
    func test___creating_fbxctest_sim_folder() {
        assertDoesNotThrow {
            let tempFolder = try TemporaryFolder(deleteOnDealloc: true)
            let simulatorPath = try tempFolder.createFile(components: ["simulator_set", udid.value], filename: "flag", contents: nil).removingLastComponent
            let simFolderContainerPath = try tempFolder.pathByCreatingDirectories(components: ["simfolder"])
            let simFolder = try creator.createSimFolderForFbxctest(
                containerPath: simFolderContainerPath,
                simulatorPath: simulatorPath
            )
            
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: simFolder.appending(components: ["sim", "device_set.plist"]).pathString),
                "device_set.plist should be created"
            )
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: simFolder.appending(components: ["sim", udid.value, "flag"]).pathString),
                "Simulator contents should be reachable via symlink"
            )
        }
    }
}
