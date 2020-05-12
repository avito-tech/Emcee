import Foundation
import FileSystem

public final class DefaultProcessControllerProvider: ProcessControllerProvider {
    private let fileSystem: FileSystem
    
    public init(
        fileSystem: FileSystem
    ) {
        self.fileSystem = fileSystem
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        return try DefaultProcessController(
            fileSystem: fileSystem,
            subprocess: subprocess
        )
    }
}
