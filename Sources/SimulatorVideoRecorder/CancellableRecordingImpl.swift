import Foundation
import EmceeLogging
import PathLib
import ProcessController

class CancellableRecordingImpl: CancellableRecording {
    private let outputPath: AbsolutePath
    private let recordingProcess: ProcessController

    public init(
        outputPath: AbsolutePath,
        recordingProcess: ProcessController
    ) {
        self.outputPath = outputPath
        self.recordingProcess = recordingProcess
    }
    
    func stopRecording() -> AbsolutePath {
        recordingProcess.interruptAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        return outputPath
    }
    
    func cancelRecording() {
        recordingProcess.terminateAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: outputPath.pathString) {
            try? fileManager.removeItem(atPath: outputPath.pathString)
        }
    }
}
