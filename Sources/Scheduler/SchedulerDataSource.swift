import Foundation

public protocol SchedulerDataSource: class {
    func nextBucket() -> SchedulerBucket?
}
