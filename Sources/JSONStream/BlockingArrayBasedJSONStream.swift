import AtomicModels
import Dispatch
import Foundation

public final class BlockingArrayBasedJSONStream: AppendableJSONStream {
    private let readLock = NSLock()
    private let writeLock = DispatchSemaphore(value: 0)
    
    private let storage = AtomicValue<[UInt8]>([])
    
    private var willProvideMoreData = true
    
    public init() {}
    
    public func append(bytes: [UInt8]) {
        storage.withExclusiveAccess {
            $0.insert(contentsOf: bytes.reversed(), at: 0)
        }
        onNewData()
    }
    
    // MARK: - JSONStream
    
    public func touch() -> UInt8? {
        return lastByte(delete: false)
    }
    
    public func read() -> UInt8? {
        return lastByte(delete: true)
    }
    
    public func close() {
        willProvideMoreData = false
        onStreamClose()
    }
    
    private func lastByte(delete: Bool) -> UInt8? {
        readLock.lock()
        defer {
            readLock.unlock()
        }
        
        if storage.currentValue().isEmpty {
            if willProvideMoreData {
                waitForNewDataOrStreamCloseEvent()
            } else {
                return nil
            }
        }
        
        return storage.withExclusiveAccess {
            if delete {
                return $0.popLast()
            } else {
                return $0.last
            }
        }
    }
    
    private func waitForNewDataOrStreamCloseEvent() {
        writeLock.waitForUnblocking()
    }
    
    private func onNewData() {
        writeLock.unblock()
    }
    
    private func onStreamClose() {
        writeLock.unblock()
    }
}

extension DispatchSemaphore {
    func waitForUnblocking() {
        wait()
        signal()
    }
    
    func unblock() {
        signal()
        wait()
    }
}
