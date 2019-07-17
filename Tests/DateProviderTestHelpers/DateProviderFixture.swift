import Foundation
import DateProvider

public final class DateProviderFixture: DateProvider {
    public var result: Date
    
    public init(_ date: Date = Date()) {
        self.result = date
    }
    
    public func with(date: Date) -> Self {
        result = date
        return self
    }
    
    public func currentDate() -> Date {
        return result
    }
}
