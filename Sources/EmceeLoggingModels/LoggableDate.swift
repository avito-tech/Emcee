import Foundation

public final class LoggableDate: CustomStringConvertible {
    private let date: Date
    private let dateFormatter: DateFormatter
    
    public init(
        _ date: Date,
        dateFormatter: DateFormatter = NSLogLikeLogEntryTextFormatter.logDateFormatter
    ) {
        self.date = date
        self.dateFormatter = dateFormatter
    }
    
    public var description: String {
        dateFormatter.string(from: date)
    }
}

extension Date {
    public func loggable(
        dateFormatter: DateFormatter = NSLogLikeLogEntryTextFormatter.logDateFormatter
    ) -> LoggableDate {
        LoggableDate(self, dateFormatter: dateFormatter)
    }
}
