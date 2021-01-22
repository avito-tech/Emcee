import Foundation
import PathLib
import ProcessController

public protocol UpdatingFileReader {
    func read(handler: @escaping (Data) -> ()) throws -> UpdatingFileReaderHandle
}

public final class UpdatingFileReaderImpl: UpdatingFileReader {
    private let path: AbsolutePath
    private let processControllerProvider: ProcessControllerProvider
    
    public init(
        path: AbsolutePath,
        processControllerProvider: ProcessControllerProvider
    ) throws {
        self.path = path
        self.processControllerProvider = processControllerProvider
    }
    
    public func read(handler: @escaping (Data) -> ()) throws -> UpdatingFileReaderHandle {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/tail", "-f", "-n", "+1", path.pathString]
            )
        )
        processController.onStdout { _, data, _ in
            handler(data)
        }
        processController.start()
        return ProcessUpdatingFileReaderHandle(processController: processController)
    }
}
