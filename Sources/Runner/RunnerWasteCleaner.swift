import FileSystem
import Foundation

public protocol RunnerWasteCleaner {
    func cleanWaste(runnerWasteCollector: RunnerWasteCollector)
}

public final class RunnerWasteCleanerImpl: RunnerWasteCleaner {
    private let fileSystem: FileSystem
    
    public init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
    }
    
    public func cleanWaste(runnerWasteCollector: RunnerWasteCollector) {
        for path in runnerWasteCollector.collectedPaths {
            if fileSystem.properties(forFileAtPath: path).exists() {
                try? fileSystem.delete(path: path)
            }
        }
    }
}
