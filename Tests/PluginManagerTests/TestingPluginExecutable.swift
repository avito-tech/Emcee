import EmceeExtensions
import Foundation
import FileSystem
import PathLib

final class TestingPluginExecutable {
    
    private static let fileSystem = LocalFileSystemProvider().create()
    
    public static let testingPluginPath: String? = buildTestingPlugin()
    
    private static func buildTestingPlugin() -> String? {
        guard let swiftPackagePath = walkUpTheHierarchy(
            startingAtPath: AbsolutePath(#file),
            untilFileIsFound: "Package.swift"
        ) else {
            return nil
        }
        
        let process = Process.launchedProcess(
            launchPath: "/usr/bin/swift",
            arguments: [
                "build",
                "--package-path", swiftPackagePath.pathString,
                "--product", "testing_plugin"
            ])
        process.waitUntilExit()
        let location = swiftPackagePath.appending(".build", "debug", "testing_plugin")
        if fileSystem.properties(forFileAtPath: location).exists() {
            return location.pathString
        } else {
            return nil
        }
    }
    
    private static func walkUpTheHierarchy(
        startingAtPath path: AbsolutePath,
        untilFileIsFound filename: String
    ) -> AbsolutePath? {
        var path = path
        
        while !path.isRoot {
            if fileSystem.properties(forFileAtPath: path.appending(filename)).exists() {
                return path
            }
            
            path = path.removingLastComponent
        }
        return nil
    }
}
