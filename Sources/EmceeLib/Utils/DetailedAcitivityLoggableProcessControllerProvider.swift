import DI
import Foundation
import EmceeLogging
import LoggingSetup
import PathLib
import ProcessController

public final class DetailedAcitivityLoggableProcessControllerProvider: ProcessControllerProvider {
    private let processControllerProvider: LoggableProcessControllerProvider
    
    public init(
        di: DI
    ) throws {
        processControllerProvider = LoggableProcessControllerProvider(
            pathProvider: { processName -> (stdout: AbsolutePath, stderr: AbsolutePath) in
                let paths = try di.get(LoggingSetup.self).childProcessLogsContainerProvider().paths(subprocessName: processName)
                Logger.debug("Subprocess output will be stored: stdout: \(paths.stdout) stderr: \(paths.stderr)")
                return paths
            },
            provider: DefaultProcessControllerProvider(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            )
        )
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        let processController = try processControllerProvider.createProcessController(subprocess: subprocess)
        
        processController.onStart { sender, _ in
            Logger.debug("Started subprocess: \(sender.subprocess)", sender.subprocessInfo.pidInfo)
        }
        
        processController.onSignal { sender, signal, _ in
            Logger.debug("Signalled \(signal)", sender.subprocessInfo.pidInfo)
        }
        
        processController.onTermination { sender, _ in
            Logger.debug("Process terminated", sender.subprocessInfo.pidInfo)
        }
        
        return processController
    }
}

extension SubprocessInfo {
    var pidInfo: PidInfo {
        PidInfo(pid: subprocessId, name: subprocessName)
    }
}
