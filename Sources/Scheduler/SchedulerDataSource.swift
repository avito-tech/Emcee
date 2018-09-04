import Foundation
import Models

public protocol SchedulerDataSource {
    func nextBucket() -> Bucket?
}
