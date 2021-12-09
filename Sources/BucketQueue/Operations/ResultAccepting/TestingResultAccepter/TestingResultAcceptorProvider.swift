import EmceeLogging
import Foundation

public protocol TestingResultAcceptorProvider {
    func create(
        bucketQueueHolder: BucketQueueHolder
    ) -> TestingResultAcceptor
}
