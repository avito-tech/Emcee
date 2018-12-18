import Foundation

public protocol StuckBucketsReenqueuer {
    func reenqueueStuckBuckets() -> [StuckBucket]
}
