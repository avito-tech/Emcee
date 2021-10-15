import Foundation
import DateProvider

public final class MeasurerImpl: Measurer {
    private let dateProvider: DateProvider
    
    public init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
    }
    
    public func measure<T>(
        work: () throws -> T
    ) -> MeasurementResult<T> {
        let start = dateProvider.currentDate()
        do {
            let value = try work()
            let end = dateProvider.currentDate()
            
            return MeasurementResult(
                result: .success(value),
                startTime: start,
                duration: end.timeIntervalSince(start)
            )
        } catch {
            return MeasurementResult(
                result: .error(error),
                startTime: start,
                duration: dateProvider.currentDate().timeIntervalSince(start)
            )
        }
    }

}
