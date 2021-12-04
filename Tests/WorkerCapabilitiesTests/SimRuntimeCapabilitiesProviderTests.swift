import FileSystem
import FileSystemTestHelpers
import Foundation
import PlistLib
import Tmp
import TestHelpers
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class SimRuntimeCapabilitiesProviderTests: XCTestCase {
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    
    func test___discovering_simruntimes() throws {
        try tempFolder.createFile(
            components: ["Library", "Developer", "CoreSimulator", "Profiles", "Runtimes", "iOS 123.456.simruntime", "Contents"],
            filename: "Info.plist",
            contents: try plist(
                bundleId: "com.apple.CoreSimulator.SimRuntime.iOS-123-456",
                bundleName: "iOS 123.456"
            ).data(format: .xml)
        )
        
        try tempFolder.createFile(
            components: ["Library", "Developer", "CoreSimulator", "Profiles", "Runtimes", "iOS 1.4.simruntime", "Contents"],
            filename: "Info.plist",
            contents: try plist(
                bundleId: "whatever.SimRuntime.iOS-1-4",
                bundleName: "iOS 1.4"
            ).data(format: .xml)
        )
        
        _ = try tempFolder.createDirectory(
            components: ["Library", "Developer", "CoreSimulator", "Profiles", "Runtimes", "iOS X.Y.simruntime", "Contents"]
        )
        
        fileSystem.fakeContentEnumerator = { args in
            ShallowFileSystemEnumerator(fileManager: FileManager(), path: args.path)
        }

        let provider = SimRuntimeCapabilitiesProvider(fileSystem: fileSystem, logger: .noOp)
        XCTAssertEqual(
            provider.workerCapabilities(),
            [
                WorkerCapability(
                    name: SimRuntimeCapabilitiesProvider.workerCapabilityName(
                        simRuntimeBundleIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-123-456"
                    ),
                    value: "iOS 123.456"
                ),
                WorkerCapability(
                    name: SimRuntimeCapabilitiesProvider.workerCapabilityName(
                        simRuntimeBundleIdentifier: "whatever.SimRuntime.iOS-1-4"
                    ),
                    value: "iOS 1.4"
                ),
            ]
        )
    }
    
    private func plist(bundleId: String, bundleName: String) -> Plist {
        Plist(
            rootPlistEntry: .dict(
                [
                    "CFBundleIdentifier": .string(bundleId),
                    "CFBundleName": .string(bundleName),
                ]
            )
        )
    }
}
