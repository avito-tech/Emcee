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
        Logger.verboseDebug("Stopping recording into \(outputPath)")
        recordingProcess.interruptAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        Logger.debug("Recoring process interrupted")
        return outputPath
    }
    
    func cancelRecording() {
        Logger.verboseDebug("Cancelling recording into \(outputPath)")
        recordingProcess.terminateAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        
        if FileManager.default.fileExists(atPath: outputPath.pathString) {
            try? FileManager.default.removeItem(atPath: outputPath.pathString)
        }
        
        Logger.debug("Recoring process cancelled")
    }
}
