import Foundation
import PathLib
import ProcessController

public protocol ObservableFileReader {
    func read(handler: @escaping (Data) -> ()) throws -> ObservableFileReaderHandler
}

public final class ObservableFileReaderImpl: ObservableFileReader {
    private let path: AbsolutePath
    private let processControllerProvider: ProcessControllerProvider
    
    public init(
        path: AbsolutePath,
        processControllerProvider: ProcessControllerProvider
    ) {
        self.path = path
        self.processControllerProvider = processControllerProvider
    }
    
    public func read(handler: @escaping (Data) -> ()) throws -> ObservableFileReaderHandler {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/tail", "-f", "-n", "+1", path.pathString]
            )
        )
        processController.onStdout { _, data, _ in
            handler(data)
        }
        processController.start()
        return ProcessObservableFileReaderHandler(processController: processController)
    }
}

public final class FileHandleObservableFileReaderImpl: ObservableFileReader {
    private let path: AbsolutePath

    public init(
        path: AbsolutePath
    ) {
        self.path = path
    }
    
    public func read(handler: @escaping (Data) -> ()) throws -> ObservableFileReaderHandler {
        let fileHandle = try FileHandle(forReadingFrom: path.fileUrl)
        fileHandle.readabilityHandler = { sender in
            handler(sender.availableData)
        }
        return FileHandlerObservableFileReaderHandler(fileHandle: fileHandle)
    }

    private class FileHandlerObservableFileReaderHandler: ObservableFileReaderHandler {
        private let fileHandle: FileHandle
        
        init(fileHandle: FileHandle) {
            self.fileHandle = fileHandle
        }
        
        func cancel() {
            fileHandle.readabilityHandler = nil
        }
    }
}
