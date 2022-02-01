import AtomicModels
import Foundation

public final class CachingSynchronousMyAddressFetcher: SynchronousMyAddressFetcher {
    private let wrapped: SynchronousMyAddressFetcher
    private let cachedResult = AtomicValue<String?>(nil)
    
    public init(wrapped: SynchronousMyAddressFetcher) {
        self.wrapped = wrapped
    }
    
    public func fetch(timeout: TimeInterval) throws -> String {
        return try cachedResult.withExclusiveAccess { value in
            if let value = value {
                return value
            }
            
            let result = try wrapped.fetch(timeout: timeout)
            value = result
            return result
        }
    }
}
