import Foundation

/// A lock that multiple processes on same host can use to restrict access to some shared resource, such as a file.
/// It can be locked recursively from the same thread.
/// Calls to `lock()` must be balanced by same number of `unlock()` calls.
///
/// - Two instances locking on the same resource won't behave as a recursive lock.
/// - If unbalanced `unlock()` call is detected `Error` will be thrown.
public final class FileLock {
    private let fileDescriptor: Int32
    private let recursiveLock = NSRecursiveLock()
    private var counter = 0
    
    public enum FileLockError: Error, CustomStringConvertible {
        case errno(Int32)
        case unbalancedUnlockCalls
        
        public var description: String {
            switch self {
            case .errno(let code):
                guard let systemDescription = strerror(code) else { return "Error: errno \(code)" }
                let message = String(validatingUTF8: systemDescription) ?? "Unknown Error"
                return "\(message) (errno \(code))"
            case .unbalancedUnlockCalls:
                return "Unbalanced number of calls: unlock() has been called more that lock()"
            }
        }
    }
    
    public static func named(_ name: String) throws -> FileLock {
        let tempFolderPath = NSTemporaryDirectory() as NSString
        return try FileLock(lockFilePath: tempFolderPath.appendingPathComponent(name + ".lock"))
    }

    public init(lockFilePath: String) throws {
        fileDescriptor = open(lockFilePath, O_WRONLY | O_CREAT | O_CLOEXEC, 0o666)
        if fileDescriptor == -1 {
            throw FileLockError.errno(errno)
        }
    }
    
    deinit {
        close(fileDescriptor)
    }
    
    public func lock() throws {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        
        counter += 1
        if counter > 1 {
            return
        }
        
        while true {
            if flock(fileDescriptor, LOCK_EX) == 0 {
                break
            }
            // Retry if interrupted.
            if errno == EINTR { continue }
            throw FileLockError.errno(errno)
        }
    }
    
    public func unlock() throws {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        
        guard counter > 0 else {
            throw FileLockError.unbalancedUnlockCalls
        }
        
        counter -= 1
        
        if counter == 0 {
            flock(fileDescriptor, LOCK_UN)
        }
    }
    
    /// Attempts to lock. If this method returns `true`, you must `unlock()`.
    public func tryToLock() -> Bool {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        
        let result = flock(fileDescriptor, LOCK_EX | LOCK_NB) == 0
        if result {
            counter += 1
        }
        return result
    }
    
    public var isLocked: Bool {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        
        return counter > 0
    }
    
    public func whileLocked<T>(work: () throws -> (T)) throws -> T {
        try lock()
        
        do {
            let result = try work()
            try unlock()
            return result
        } catch {
            try unlock()
            throw error
        }
    }
}
