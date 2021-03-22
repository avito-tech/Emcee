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
        self.logger = logger.forType(Self.self)
    }
    
    public func printQueueSize() {
        let dequeuedTests = runningQueueState.dequeuedTests.asDictionary
        
        for workerId in Array(dequeuedTests.keys).sorted() {
            if let testsOnWorker = dequeuedTests[workerId] {
                print("\(workerId.value) is executing \(testsOnWorker.map { $0.stringValue }.sorted().joined(separator: ", "))")
            }
        }

        logger
            .skippingKibana
            .info("Enqueued tests: \(runningQueueState.enqueuedTests.count), running tests: \(runningQueueState.dequeuedTests.flattenValues.count)")
    }
}
