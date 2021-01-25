import Foundation
import FileSystem
import PathLib
import Tmp

public protocol ChildProcessLogsContainerProvider {
    func paths(subprocessName: String) throws -> (stdout: AbsolutePath, stderr: AbsolutePath)
}

public final class ChildProcessLogsContainerProviderImpl: ChildProcessLogsContainerProvider {
    private let fileSystem: FileSystem
    private let mainContainerPath: AbsolutePath
    
    public init(
        fileSystem: FileSystem,
        mainContainerPath: AbsolutePath
    ) {
        self.fileSystem = fileSystem
        self.mainContainerPath = mainContainerPath
    }
    
    public func paths(subprocessName: String) throws -> (stdout: AbsolutePath, stderr: AbsolutePath) {
        let subprocessSpecificContainer = mainContainerPath.appending(
            components: ["subprocesses", subprocessName]
        )
        let processContainer = try TemporaryFolder(
            containerPath: subprocessSpecificContainer,
            prefix: subprocessName,
            deleteOnDealloc: false
        ).absolutePath
        
        let stdoutPath = processContainer.appending(component: "stdout.log")
        let stderrPath = processContainer.appending(component: "stderr.log")
        
        try fileSystem.createDirectory(atPath: processContainer, withIntermediateDirectories: true)
        try fileSystem.createFile(atPath: stdoutPath, data: nil)
        try fileSystem.createFile(atPath: stderrPath, data: nil)
        
        return (stdout: stdoutPath, stderr: stderrPath)
    }
}
