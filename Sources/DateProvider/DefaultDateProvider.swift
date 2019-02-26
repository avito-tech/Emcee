import Foundation

public final class SystemDateProvider: DateProvider {
    public init() {}
    
    public func currentDate() -> Date {
        return Date()
    }
}
