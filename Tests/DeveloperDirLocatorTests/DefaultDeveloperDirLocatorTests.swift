import DeveloperDirLocator
import Foundation
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import TestHelpers
import Tmp
import XCTest

final class DefaultDeveloperDirLocatorTests: XCTestCase {
    let currentDeveloperDirPath = AbsolutePath("/expected/path/to/developer/dir")
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    lazy var processControllerProvider = FakeProcessControllerProvider() { subprocess -> ProcessController in
        XCTAssertEqual(
            try subprocess.arguments.map { try $0.stringValue() },
            ["/usr/bin/xcode-select", "-p"]
        )
        
        let processController = FakeProcessController(subprocess: subprocess)
        processController.onStart { _, unsubscribe in
            processController.broadcastStdout(data: Data(self.currentDeveloperDirPath.pathString.utf8))
            unsubscribe()
        }
        return processController
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
