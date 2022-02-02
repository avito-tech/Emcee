import EmceeLoggingModels
import Foundation
import ProcessController
import QueueModels

public enum SubprocessPipe: String {
    case stdout
    case stderr
}

public extension ContextualLogger {
    func attachToProcess(
        processController: ProcessController,
        workerId: WorkerId? = nil,
        persistentMetricsJobId: String? = nil,
        source: String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let work = { [weak self] (sender: ProcessController, data: Data, unsubscriber: Unsubscribe, subprocessPipe: SubprocessPipe) in
            guard let strongSelf = self else {
                unsubscriber()
                return
            }
            strongSelf.messageFromData(
                data,
                subprocessPipe: subprocessPipe,
                subprocessPidInfo: sender.subprocessInfo.pidInfo,
                workerId: workerId,
                persistentMetricsJobId: persistentMetricsJobId,
                source: source,
                file: file,
                function: function,
                line: line
            )
        }
        
        processController.onStdout { sender, data, unsubscriber in 
            work(sender, data, unsubscriber, .stdout)
        }
        processController.onStderr { sender, data, unsubscriber in 
            work(sender, data, unsubscriber, .stderr)
        }
    }
    
    private func messageFromData(
        _ data: Data,
        subprocessPipe: SubprocessPipe,
        subprocessPidInfo: PidInfo?,
        workerId: WorkerId?,
        persistentMetricsJobId: String?,
        source: String?,
        file: String,
        function: String,
        line: UInt
    ) {
        let logger = withMetadata(key: "subprocessPipe", value: subprocessPipe.rawValue)
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error(
                "Failed to get string from data (\(data.count) bytes), BASE64: \(data.base64EncodedString())",
                subprocessPidInfo: subprocessPidInfo,
                workerId: workerId,
                persistentMetricsJobId: persistentMetricsJobId,
                source: source,
                file: file,
                function: function,
                line: line
            )
            return
        }
        logger.debug(
            string,
            subprocessPidInfo: subprocessPidInfo,
            workerId: workerId,
            persistentMetricsJobId: persistentMetricsJobId,
            source: source,
            file: file,
            function: function,
            line: line
        )
    }
}
