import Foundation

internal protocol DateProvider {
    func currentDate() -> Date
}

internal final class DefaultDateProvider: DateProvider {
    func currentDate() -> Date {
        return Date()
    }
}
