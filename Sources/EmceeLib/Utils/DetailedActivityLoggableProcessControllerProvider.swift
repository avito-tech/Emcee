import DI
import Foundation
import EmceeLogging
import Extensions
import LoggingSetup
import PathLib
import ProcessController

public final class DetailedActivityLoggableProcessControllerProvider: ProcessControllerProvider {
    private let di: DI
    
    public init(
        di: DI
    ) throws {
        self.di = di
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        let logger = try di.get(ContextualLogger.self)
        
        let paths = try di.get(LoggingSetup.self).childProcessLogsContainerProvider().paths(
            subprocessName: try subprocess.processName()
        )
        
        let processControllerProvider = LoggableProcessControllerProvider(
            pathProvider: { _ in paths },
            provider: DefaultProcessControllerProvider(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            )
        )

        let processController = try processControllerProvider.createProcessController(subprocess: subprocess)
        
        processController.onStart { [logger] sender, _ in
            logger.debug("Started subprocess: \(sender.subprocess), output will be stored: stdout: \(paths.stdout) stderr: \(paths.stderr)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
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

private extension Subprocess {
    func processName() throws -> String {
        return try arguments[0].stringValue().lastPathComponent
    }
}
