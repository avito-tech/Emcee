import DeveloperDirLocator
import Foundation
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import TestHelpers
import TemporaryStuff
import XCTest

final class DefaultDeveloperDirLocatorTests: XCTestCase {
    let currentDeveloperDirPath = AbsolutePath("/expected/path/to/developer/dir")
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    lazy var processControllerProvider = FakeProcessControllerProvider(tempFolder: tempFolder) { subprocess -> ProcessController in
        XCTAssertEqual(
            try subprocess.arguments.map { try $0.stringValue() },
            ["/usr/bin/xcode-select", "-p"]
        )
        self.assertDoesNotThrow {
            try self.currentDeveloperDirPath.pathString.write(
                to: subprocess.standardStreamsCaptureConfig.stdoutOutputPath().fileUrl,
                atomically: true,
                encoding: .utf8
            )
        }
        return FakeProcessController(subprocess: subprocess)
    }
    
    func test___current_developer_dir() throws {
        XCTAssertEqual(
            try DefaultDeveloperDirLocator(processControllerProvider: processControllerProvider).path(developerDir: .current),
            currentDeveloperDirPath
        )
    }
    
    func test___choosing_correct_xcode() throws {
        let tempFolder = try TemporaryFolder()
        try tempFolder.createFile(components: ["Xcode1021.app", "Contents"], filename: "Info.plist", contents: try plistData(bundleVersion: "10.2.1"))
        try tempFolder.createFile(components: ["Xcode101.app", "Contents"], filename: "Info.plist", contents: try plistData(bundleVersion: "10.1"))
        
        let result = try DefaultDeveloperDirLocator(
            processControllerProvider: processControllerProvider,
            xcodeAppContainerPath: tempFolder.absolutePath
        ).path(developerDir: .useXcode(CFBundleShortVersionString: "10.1"))
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
