import DeveloperDirLocator
import Foundation
import Models
import PathLib
import ProcessController
import TemporaryStuff
import XCTest

final class DefaultDeveloperDirLocatorTests: XCTestCase {
    func test___current_developer_dir() throws {
        let processController = try DefaultProcessController(subprocess: Subprocess(arguments: ["/usr/bin/xcode-select", "-p"]))
        processController.startAndListenUntilProcessDies()
        let expectedPath = AbsolutePath(
            try String(
                contentsOf: processController.subprocess.standardStreamsCaptureConfig.stdoutContentsFile.fileUrl
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        )
        XCTAssertEqual(
            try DefaultDeveloperDirLocator().path(developerDir: .current),
            expectedPath
        )
    }
    
    func test___choosing_correct_xcode() throws {
        let tempFolder = try TemporaryFolder()
        try tempFolder.createFile(components: ["Xcode1021.app", "Contents"], filename: "Info.plist", contents: try plistData(bundleVersion: "10.2.1"))
        try tempFolder.createFile(components: ["Xcode101.app", "Contents"], filename: "Info.plist", contents: try plistData(bundleVersion: "10.1"))
        
        let result = try DefaultDeveloperDirLocator(xcodeAppContainerPath: tempFolder.absolutePath).path(developerDir: .useXcode(CFBundleShortVersionString: "10.1"))
        XCTAssertEqual(
            result,
            tempFolder.pathWith(components: ["Xcode101.app", "Contents", "Developer"])
        )
    }
    
    private func plistData(bundleVersion: String) throws -> Data {
        let dict = [
            "CFBundleShortVersionString": bundleVersion,
            "CFBundleIdentifier": "com.apple.dt.Xcode"
        ]
        return try PropertyListSerialization.data(fromPropertyList: dict as NSDictionary, format: .xml, options: 0)
    }
}
