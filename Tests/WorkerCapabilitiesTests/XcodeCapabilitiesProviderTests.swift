import FileSystem
import FileSystemTestHelpers
import Foundation
import PlistLib
import Tmp
import TestHelpers
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class XcodeCapabilitiesProviderTests: XCTestCase {
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    
    func test___discovering_xcodes() throws {
        try tempFolder.createFile(components: ["Applications", "Xcode115.app", "Contents"], filename: "Info.plist", contents: try plist(shortVersion: "11.5").data(format: .xml))
        try tempFolder.createFile(components: ["Applications", "Xcode101.app", "Contents"], filename: "Info.plist", contents: try plist(shortVersion: "10.1").data(format: .xml))
        _ = try tempFolder.createDirectory(components: ["Applications", "Xcode123.app"])
        
        fileSystem.fakeContentEnumerator = { args in
            ShallowFileSystemEnumerator(fileManager: FileManager(), path: args.path)
        }

        let provider = XcodeCapabilitiesProvider(fileSystem: fileSystem, logger: .noOp)
        XCTAssertEqual(
            provider.workerCapabilities(),
            [
                WorkerCapability(name: XcodeCapabilitiesProvider.workerCapabilityName(shortVersion: "11.5"), value: "11.5"),
                WorkerCapability(name: XcodeCapabilitiesProvider.workerCapabilityName(shortVersion: "10.1"), value: "10.1"),
            ]
        )
    }
    
    private func plist(shortVersion: String) -> Plist {
        Plist(
            rootPlistEntry: .dict(
                [
                    "CFBundleShortVersionString": .string(shortVersion),
                    "CFBundleIdentifier": .string("com.apple.dt.Xcode"),
                ]
            )
        )
    }
}
