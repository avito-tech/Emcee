import Foundation
import EmceeLogging
import QueueModels

public final class BucketQueueStateLogger {
    private let runningQueueState: RunningQueueState
    private let logger: ContextualLogger
    
    public init(
        runningQueueState: RunningQueueState,
        logger: ContextualLogger
    ) {
        self.runningQueueState = runningQueueState
        self.logger = logger
    }
    
    public func printQueueSize() {
        let dequeuedTests = runningQueueState.dequeuedTests.asDictionary
        
        let logger = logger.skippingKibana
        
        for workerId in Array(dequeuedTests.keys).sorted() {
            if let testsOnWorker = dequeuedTests[workerId] {
                logger.info("\(workerId.value) is executing \(testsOnWorker.map(\.stringValue).sorted().joined(separator: ", "))")
            }
        }

        logger.info("Enqueued tests: \(runningQueueState.enqueuedTests.count), running tests: \(runningQueueState.dequeuedTests.flattenValues.count)")
    }
}
