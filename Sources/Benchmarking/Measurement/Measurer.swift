import Foundation

public protocol Measurer {
    func measure<T>(
        work: () throws -> T
    ) -> MeasurementResult<T>
}
