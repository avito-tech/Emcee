import Foundation
import Models
import ProcessController

public final class SimulatorVideoRecorder {
    private let simulatorUuid: UUID
    private let simulatorSetPath: String

    public init(simulatorUuid: UUID, simulatorSetPath: String) {
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
    }
    
    public func startRecording(outputPath: String) throws -> CancellableRecording {
        let processController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl",
                    "--set",
                    simulatorSetPath,
                    "io",
                    simulatorUuid.uuidString,
                    "recordVideo",
                    "--type=mp4",
                    outputPath
                ]
            )
        )
        processController.start()

        return CancellableRecordingImpl(
            outputPath: outputPath,
            recordingProcess: processController
        )
    }
}
