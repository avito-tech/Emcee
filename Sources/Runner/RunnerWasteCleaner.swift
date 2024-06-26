import EmceeLogging
import FileSystem
import Foundation

public protocol RunnerWasteCleaner {
    func cleanWaste(runnerWasteCollector: RunnerWasteCollector)
}

public final class RunnerWasteCleanerImpl: RunnerWasteCleaner {
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    
    public init(fileSystem: FileSystem, logger: ContextualLogger) {
        self.fileSystem = fileSystem
        self.logger = logger
    }
    
    public func cleanWaste(runnerWasteCollector: RunnerWasteCollector) {
        for path in runnerWasteCollector.collectedPaths {
            if fileSystem.properties(forFileAtPath: path).exists() {
                logger.debug("Deleting \(path)")
                try? fileSystem.delete(path: path)
            }
        }
    }
}

public final class NoOpRunnerWasteCleaner: RunnerWasteCleaner {
    private let logger: ContextualLogger
    
    public init(
        logger: ContextualLogger
    ) {
        self.logger = logger
    }
    
    public func cleanWaste(runnerWasteCollector: RunnerWasteCollector) {
        for path in runnerWasteCollector.collectedPaths {
            logger.debug("Skipping clean up of: \(path)")
        }
    }
}
 
