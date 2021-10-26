import DateProvider
import EmceeLogging
import Foundation
import ResultStreamModels
import PathLib
import ProcessController
import Runner

public final class XcResultToolImpl: XcResultTool {
    private let dateProvider: DateProvider
    private let logger: ContextualLogger
    private let processControllerProvider: ProcessControllerProvider
    
    public init(
        dateProvider: DateProvider,
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider
    ) {
        self.dateProvider = dateProvider
        self.logger = logger
        self.processControllerProvider = processControllerProvider
    }
    
    public func get(path: AbsolutePath) throws -> RSActionsInvocationRecord {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "xcresulttool",
                    "get", "--path", path,
                    "--format", "json"
                ]
            )
        )

        var data = Data()
        processController.onStdout { _, chunk, _ in data.append(chunk) }
        try processController.startAndWaitForSuccessfulTermination()
        
        return try JSONDecoder().decode(RSActionsInvocationRecord.self, from: data)
    }
}
