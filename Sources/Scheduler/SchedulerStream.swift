import Foundation
import Models

public protocol SchedulerStream {
    
    /** Called when Scheduler receives a TestingResult for a Bucket. */
    func scheduler(_ sender: Scheduler, didReceiveTestingResult testingResult: TestingResult)
    
}
