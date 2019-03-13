import Foundation
import Logging
import ProcessController

class CancellableRecordingImpl: CancellableRecording {
    private let outputPath: String
    private let recordingProcess: ProcessController

    public init(outputPath: String, recordingProcess: ProcessController) {
        self.outputPath = outputPath
        self.recordingProcess = recordingProcess
    }
    
    func stopRecording() -> String {
        Logger.verboseDebug("Stopping recording into \(outputPath)")
        recordingProcess.terminateAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        Logger.debug("Recoring process terminated")
        return outputPath
    }
}
