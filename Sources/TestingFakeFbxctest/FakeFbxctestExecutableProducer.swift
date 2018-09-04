import Extensions
import Foundation

/**
 This class builds fake fbxctest binary and prepares its output.
 */
public final class FakeFbxctestExecutableProducer {
    private static let swiftPackagePath = FileManager.default.walkUpTheHierarchy(
        path: #file,
        untilFileIsFound: "Package.swift")
    
    public static let fakeFbxctestPath: String? = buildFakeFbxctest()
    
    private static func buildFakeFbxctest() -> String? {
        guard let swiftPackagePath = FakeFbxctestExecutableProducer.swiftPackagePath else {
            return nil
        }
        
        let process = Process.launchedProcess(
            launchPath: "/usr/bin/swift",
            arguments: [
                "build",
                "--package-path", swiftPackagePath,
                "-Xswiftc", "-target", "-Xswiftc", "x86_64-apple-macosx10.13",
                "--static-swift-stdlib", "--product", "fake_fbxctest"
            ])
        process.waitUntilExit()
        let location = swiftPackagePath.appending(pathComponents: [".build", "debug", "fake_fbxctest"])
        if FileManager.default.fileExists(atPath: location) {
            return location
        } else {
            return nil
        }
    }
    
    public static let fakeOutputJsonFilename = "fake_output.json"
    
    public static func setFakeOutputEvents(runIndex: Int = 0, _ events: [AnyEncodableWrapper]) throws {
        guard let binaryPath = fakeFbxctestPath else { return }
        let jsonPath = binaryPath
            .deletingLastPathComponent
            .appending(pathComponent:
                "\(FakeFbxctestExecutableProducer.fakeOutputJsonFilename.deletingPathExtension)_\(runIndex).\(FakeFbxctestExecutableProducer.fakeOutputJsonFilename.pathExtension)")
        
        let encoder = JSONEncoder()
        try Data().write(to: URL(fileURLWithPath: jsonPath))
        if let handle = FileHandle(forWritingAtPath: jsonPath) {
            let newLineCharacterData = Data(bytes: [UInt8(10)])
            for event in events {
                let data = try encoder.encode(event)
                handle.write(data)
                handle.write(newLineCharacterData)
            }
            handle.closeFile()
        }
    }
    
    public static func eraseFakeOutputEvents() throws {
        guard let binaryPath = FakeFbxctestExecutableProducer.fakeFbxctestPath else { return }
        let binaryContainerPath = binaryPath.deletingLastPathComponent
        let jsonOutputFiles = try? FileManager.default.findFiles(
            path: binaryContainerPath,
            prefix: FakeFbxctestExecutableProducer.fakeOutputJsonFilename.deletingPathExtension,
            pathExtension: FakeFbxctestExecutableProducer.fakeOutputJsonFilename.pathExtension)
        try jsonOutputFiles?.forEach {
            try FileManager.default.removeItem(atPath: $0)
        }
    }
}
