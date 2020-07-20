import Foundation
import Models
import PathLib
import ProcessController
import SimulatorPoolModels

public final class SimulatorVideoRecorder {
    public enum CodecType: String {
        case h264
        case hevc
    }
    
    private let processControllerProvider: ProcessControllerProvider
    private let simulatorUuid: UDID
    private let simulatorSetPath: AbsolutePath

    public init(
        processControllerProvider: ProcessControllerProvider,
        simulatorUuid: UDID,
        simulatorSetPath: AbsolutePath
    ) {
        self.processControllerProvider = processControllerProvider
        self.simulatorUuid = simulatorUuid
        self.simulatorSetPath = simulatorSetPath
    }
    
    public func startRecording(
        codecType: CodecType,
        outputPath: AbsolutePath
    ) throws -> CancellableRecording {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl",
                    "--set",
                    simulatorSetPath,
                    "io",
                    simulatorUuid.value,
                    "recordVideo",
                    "--codec=\(codecType.rawValue)",
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
