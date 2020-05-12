@testable import Deployer
import Extensions
import Foundation
import PathLib
import TemporaryStuff
import TestHelpers
import XCTest

class DeployableBundleTests: XCTestCase {
    private let bundleName = "BundleName.bundle"
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    func test___includes_files_in_subfolders() throws {
        let bundlePath = tempFolder.pathWith(components: [bundleName])
        let plistPath = try tempFolder.createFile(components: [bundleName, "Contents"], filename: "Info.plist")
        
        let deployableBundle = try DeployableBundle(
            name: "MyBundle",
            bundlePath: bundlePath
        )
        
        let plistFiles = deployableBundle.files.filter { file -> Bool in
            file.destination == plistPath.relativePath(anchorPath: tempFolder.absolutePath)
        }
        XCTAssertEqual(plistFiles.count, 1)
    }
}
