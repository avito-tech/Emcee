import Darwin
import Foundation
import PathLib

public final class TemporaryFile {
    public let fileHandleForWriting: FileHandle
    public let absolutePath: AbsolutePath
    private let deleteOnDealloc: Bool
    
    public init(
        containerPath: AbsolutePath? = nil,
        prefix: String = "TemporaryFile",
        suffix: String = "",
        closeOnDealloc: Bool = true,
        deleteOnDealloc: Bool = true
    ) throws {
        let containerPath = containerPath ?? AbsolutePath(NSTemporaryDirectory())
        let pathTemplate = containerPath.appending(component: "\(prefix).XXXXXX\(suffix)")
        
        var templateBytes = [UInt8](pathTemplate.pathString.utf8).map { Int8($0) } + [Int8(0)]
        let fileDescriptor = mkstemps(&templateBytes, Int32(suffix.count))
        
        if fileDescriptor == -1 {
            throw ErrnoError.failedToCreateTemporaryFile(pathTemplate, code: errno)
        }
        
        self.fileHandleForWriting = FileHandle(
            fileDescriptor: fileDescriptor,
            closeOnDealloc: closeOnDealloc
        )
        self.absolutePath = AbsolutePath(String(cString: templateBytes))
        self.deleteOnDealloc = deleteOnDealloc
    }
    
    deinit {
        if deleteOnDealloc {
            unlink(absolutePath.pathString)
        }
    }
}
