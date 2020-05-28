import AtomicModels
import DateProvider
import Foundation
import SignalHandling
import Logging

final class AutomaticManagementItemController {
    private let dateProvider: DateProvider
    private let item: AutomaticManagementItem
    private let lastActivityEvent = AtomicValue<Date?>(nil)
    
    init(
        dateProvider: DateProvider,
        item: AutomaticManagementItem
    ) {
        self.dateProvider = dateProvider
        self.item = item
    }
    
    func processReportedActivity() {
        switch item {
        case .signalAfter:
            break
        case .signalWhenSilent:
            lastActivityEvent.set(dateProvider.currentDate())
        }
    }
    
    func fireEventIfNecessary(processController: ProcessController) {
        guard processController.isProcessRunning else {
            lastActivityEvent.set(nil)
            Logger.debug("Cannot automatically manage process \(processController.processName)[\(processController.processId)]: process is not running")
            return
        }
        let lastActivityEventDate: Date
        if let eventDate = lastActivityEvent.currentValue() {
            lastActivityEventDate = eventDate
        } else {
            lastActivityEventDate = dateProvider.currentDate()
            lastActivityEvent.set(lastActivityEventDate)
        }
        
        if dateProvider.currentDate() > lastActivityEventDate.addingTimeInterval(item.timeInterval) {
            processController.send(signal: item.signal.intValue)
            lastActivityEvent.set(nil)
        }
    }
}
