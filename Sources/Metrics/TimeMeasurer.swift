import DateProvider
import Foundation

public protocol TimeMeasurer {
    func measure<T>(
        work: () throws -> T,
        result: (Error?, TimeInterval) -> ()
    ) rethrows -> T
}

public final class TimeMeasurerImpl: TimeMeasurer {
    private let dateProvider: DateProvider
    
    public init(
        dateProvider: DateProvider
    ) {
        self.dateProvider = dateProvider
    }
    
    public func measure<T>(
        work: () throws -> T,
        result: (Error?, TimeInterval) -> ()
    ) rethrows -> T {
        let startedAt = dateProvider.currentDate()
        
        do {
            let value = try work()
            result(nil, dateProvider.currentDate().timeIntervalSince(startedAt))
            return value
        } catch {
            result(error, dateProvider.currentDate().timeIntervalSince(startedAt))
            throw error
        }
        
    }
}
