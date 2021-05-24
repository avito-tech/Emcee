import Foundation

public protocol SchedulerDataSource: AnyObject {
    func nextBucket() -> SchedulerBucket?
}
