import DateProvider
import Foundation

extension DateProvider {
    public func dateSince1970ReferenceDate() -> DateSince1970ReferenceDate {
        return DateSince1970ReferenceDate(timeIntervalSince1970: currentDate().timeIntervalSince1970)
    }
}
