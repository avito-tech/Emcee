import Foundation
import EmceeLogging
import QueueModels

public final class BucketQueueStateLogger {
    private let runningQueueState: RunningQueueState
    
    public init(runningQueueState: RunningQueueState) {
        self.runningQueueState = runningQueueState
    }
    
    public func printQueueSize() {
        let dequeuedTests = runningQueueState.dequeuedTests.asDictionary
        
        for workerId in Array(dequeuedTests.keys).sorted() {
            if let testsOnWorker = dequeuedTests[workerId] {
                print("\(workerId.value) is executing \(testsOnWorker.map { $0.stringValue }.sorted().joined(separator: ", "))")
            }
        }

        print("Enqueued tests: \(runningQueueState.enqueuedTests.count), running tests: \(runningQueueState.dequeuedTests.flattenValues.count)")
    }
}
