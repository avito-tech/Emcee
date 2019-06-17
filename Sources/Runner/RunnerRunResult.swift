import Extensions
import Foundation
import Logging
import Models
import ProcessController

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
        
        printTail(filePath: subprocessStandardStreamsCaptureConfig.stdoutContentsFile)
        printTail(filePath: subprocessStandardStreamsCaptureConfig.stderrContentsFile)
    }
    
    private func printTail(filePath: String) {
        if let fileHandle = FileHandle(forReadingAtPath: filePath) {
            Logger.info("Below is the tail of \(filePath)")
            fileHandle.seekToOffsetFromEnd(offset: 10*1024)
            fileHandle.stream(toFileHandle: FileHandle.standardError)
        }
    }
}
