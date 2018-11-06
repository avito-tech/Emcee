import Extensions
import Foundation

/**
 This class builds fake fbxctest binary and prepares its output.
 */
public final class FakeFbxctestExecutableProducer {
    private static let swiftPackagePath = FileManager.default.walkUpTheHierarchy(
        path: #file,
        untilFileIsFound: "Package.swift")
    
    public enum BuildError: Error {
        case noOutput
        case swiftPackageNotFound
    }
    
    public static func fakeFbxctestPath(runId: String) throws -> String {
        return try buildFakeFbxctest(runId: runId)
    }
    
    private static func buildFakeFbxctest(runId: String) throws -> String {
        guard let swiftPackagePath = FakeFbxctestExecutableProducer.swiftPackagePath else {
            throw BuildError.swiftPackageNotFound
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
        guard FileManager.default.fileExists(atPath: location) else { throw BuildError.noOutput }
        
        let runIdLocation = "\(location)_\(runId)"
        if !FileManager.default.fileExists(atPath: runIdLocation) {
            try FileManager.default.copyItem(atPath: location, toPath: runIdLocation)
        }
        return runIdLocation
    }
    
    public static let fakeOutputJsonFilename = "fake_output.json"
    
    public static func setFakeOutputEvents(runId: String, runIndex: Int = 0, _ events: [AnyEncodableWrapper]) throws {
        let binaryPath = try fakeFbxctestPath(runId: runId)
        let jsonPath = binaryPath
            .deletingLastPathComponent
            .appending(pathComponent:
                "\(runId)_\(FakeFbxctestExecutableProducer.fakeOutputJsonFilename.deletingPathExtension)_\(runIndex).\(FakeFbxctestExecutableProducer.fakeOutputJsonFilename.pathExtension)")
        
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
}
