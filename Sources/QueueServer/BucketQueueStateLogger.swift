import Foundation
import Logging
import QueueModels

public final class BucketQueueStateLogger {
    private let runningQueueState: RunningQueueState
    
    public init(runningQueueState: RunningQueueState) {
        self.runningQueueState = runningQueueState
    }
    
    public func logQueueSize() {
        let dequeuedTests = runningQueueState.dequeuedTests.asDictionary
        
        for workerId in Array(dequeuedTests.keys).sorted() {
            if let testsOnWorker = dequeuedTests[workerId] {
                Logger.info("\(workerId.value) is executing \(testsOnWorker.map { $0.stringValue }.sorted().joined(separator: ", "))")
            }
        }

        Logger.info("Enqueued tests: \(runningQueueState.enqueuedTests.count), running tests: \(runningQueueState.dequeuedTests.flattenValues.count)")
    }
}
