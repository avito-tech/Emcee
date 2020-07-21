import Foundation
import Logging
import PathLib
import ProcessController
import RunnerModels

public final class RunnerRunResult {
    public let entriesToRun: [TestEntry]
    public let testEntryResults: [TestEntryResult]
    public let subprocessStandardStreamsCaptureConfig: StandardStreamsCaptureConfig?

    public init(
        entriesToRun: [TestEntry],
        testEntryResults: [TestEntryResult],
        subprocessStandardStreamsCaptureConfig: StandardStreamsCaptureConfig?
    ) {
        self.entriesToRun = entriesToRun
        self.testEntryResults = testEntryResults
        self.subprocessStandardStreamsCaptureConfig = subprocessStandardStreamsCaptureConfig
    }

    /// Dumps the captured contents of standard streams, helpful for debugging purposes
    public func dumpStandardStreams() {
        guard let subprocessStandardStreamsCaptureConfig = subprocessStandardStreamsCaptureConfig else { return }
        
        try? printTail(filePath: subprocessStandardStreamsCaptureConfig.stdoutOutputPath())
        try? printTail(filePath: subprocessStandardStreamsCaptureConfig.stderrOutputPath())
    }
    
    private func printTail(filePath: AbsolutePath) {
        if let fileHandle = FileHandle(forReadingAtPath: filePath.pathString) {
            Logger.info("Below is the tail of \(filePath)")
            fileHandle.seekToOffsetFromEnd(offset: 10*1024)
            fileHandle.stream(toFileHandle: FileHandle.standardError)
        }
    }
}
