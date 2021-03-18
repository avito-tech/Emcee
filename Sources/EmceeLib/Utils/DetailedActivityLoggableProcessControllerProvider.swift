import DI
import Foundation
import EmceeLogging
import LoggingSetup
import PathLib
import ProcessController

public final class DetailedActivityLoggableProcessControllerProvider: ProcessControllerProvider {
    private let processControllerProvider: LoggableProcessControllerProvider
    
    private let di: DI
    
    public init(
        di: DI
    ) throws {
        self.di = di
        
        processControllerProvider = LoggableProcessControllerProvider(
            pathProvider: { [di] processName -> (stdout: AbsolutePath, stderr: AbsolutePath) in
                let logger = try di.get(ContextualLogger.self).forType(Self.self)
                
                let paths = try di.get(LoggingSetup.self).childProcessLogsContainerProvider().paths(subprocessName: processName)
                logger.debug(
                    "Subprocess output will be stored: stdout: \(paths.stdout) stderr: \(paths.stderr)",
                    subprocessPidInfo: PidInfo(pid: 0, name: processName)
                )
                return paths
            },
            provider: DefaultProcessControllerProvider(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            )
        )
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        let logger = try di.get(ContextualLogger.self).forType(Self.self)
        let processController = try processControllerProvider.createProcessController(subprocess: subprocess)
        
        processController.onStart { [logger] sender, _ in
            logger.debug("Started subprocess: \(sender.subprocess)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
        }
        
        processController.onSignal { [logger] sender, signal, _ in
            logger.debug("Signalled \(signal)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
        }
        
        processController.onTermination { [logger] sender, _ in
            logger.debug("Process terminated", subprocessPidInfo: sender.subprocessInfo.pidInfo)
        }
        
        return processController
    }
}
