import Foundation

public protocol SchedulerDataSource {
    func nextBucket() -> SchedulerBucket?
}
