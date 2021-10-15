import Foundation
import DateProvider

public protocol TimestampProvider {
    func timestampSinceReferencePoint() -> TimeInterval
}

public final class TimestampProviderImpl: TimestampProvider {
    private let dateProvider: DateProvider
    private let referencePoint: Date
    
    public init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
        self.referencePoint = dateProvider.currentDate()
    }
    
    public func timestampSinceReferencePoint() -> TimeInterval {
        dateProvider.currentDate().timeIntervalSince(referencePoint)
    }
}
