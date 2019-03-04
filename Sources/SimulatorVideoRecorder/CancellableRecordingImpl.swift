import Foundation
import ProcessController

class CancellableRecordingImpl: CancellableRecording {
    private let outputPath: String
    private let recordingProcess: ProcessController

    public init(outputPath: String, recordingProcess: ProcessController) {
        self.outputPath = outputPath
        self.recordingProcess = recordingProcess
    }
    
    func stopRecording() -> String {
        recordingProcess.interruptAndForceKillIfNeeded()
        recordingProcess.waitForProcessToDie()
        return outputPath
    }
}
