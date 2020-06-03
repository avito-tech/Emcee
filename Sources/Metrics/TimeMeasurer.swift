import Foundation

public final class TimeMeasurer {
    private init() {}
    
    public static func measure<T>(
        result: (Bool, TimeInterval) -> (),
        work: () throws -> T
    ) rethrows -> T {
        let startedAt = Date()
        
        do {
            let value = try work()
            result(true, Date().timeIntervalSince(startedAt))
            return value
        } catch {
            result(false, Date().timeIntervalSince(startedAt))
            throw error
        }
        
    }
}
