import Dispatch
import Foundation

public final class BlockingArrayBasedJSONStream: JSONStream {
    private let readQueue = DispatchQueue(label: "ru.avito.SynchronizedArrayBasedJSONStream.readQueue")
    private let writeQueue = DispatchQueue(label: "ru.avito.SynchronizedArrayBasedJSONStream.writeQueue")
    private var storage = ThreadSafeArray<Unicode.Scalar>()
    
    public var willProvideMoreData = true {
        didSet {
            if !willProvideMoreData {
                newDataCondition.signal()
            }
        }
    }
    private let newDataCondition = NSCondition()
    
    public init() {}
    
    public func append(_ scalars: [Unicode.Scalar]) {
        writeQueue.async {
            self.storage.insert(contentsOf: scalars.reversed(), at: 0)
            self.newDataCondition.signal()
        }
    }
    
    // MARK: - JSONStream
    
    public func touch() -> Unicode.Scalar? {
        return lastScalar(delete: false)
    }
    
    public func read() -> Unicode.Scalar? {
        return lastScalar(delete: true)
    }
    
    private func lastScalar(delete: Bool) -> Unicode.Scalar? {
        return readQueue.sync {
            if storage.isEmpty {
                if willProvideMoreData {
                    newDataCondition.wait()
                } else {
                    return nil
                }
            }
            
            let scalar = storage.last
            if delete, scalar != nil {
                _ = writeQueue.sync { storage.removeLast() }
            }
            return scalar
        }
    }
}
