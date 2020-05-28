import DateProvider
import Foundation
import FileSystem

public final class DefaultProcessControllerProvider: ProcessControllerProvider {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        return try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: subprocess
        )
    }
}
