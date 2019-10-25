import Foundation
import Models
import ProcessController
import PathLib

public final class SimulatorVideoRecorder {
    public enum CodecType: String {
        case mp4
        case h264
        case fmp4
    }
    
    private let simulatorUuid: UDID
    private let simulatorSetPath: AbsolutePath

    public init(simulatorUuid: UDID, simulatorSetPath: AbsolutePath) {
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
    }
    
    public func startRecording(
        codecType: CodecType,
        outputPath: AbsolutePath
    ) throws -> CancellableRecording {
        let processController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl",
                    "--set",
                    simulatorSetPath,
                    "io",
                    simulatorUuid.value,
                    "recordVideo",
                    "--type=\(codecType.rawValue)",
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
