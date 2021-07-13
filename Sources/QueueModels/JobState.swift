import Foundation

public class JobState: Codable, CustomStringConvertible, Equatable {
    public let jobId: JobId
    public let queueState: QueueState

    public init(jobId: JobId, queueState: QueueState) {
        self.jobId = jobId
        self.queueState = queueState
    }
    
    public var description: String {
        return "<\(jobId) state: \(queueState)>"
    }
    
    public static func == (left: JobState, right: JobState) -> Bool {
        return left.jobId == right.jobId
            && left.queueState == right.queueState
    }
}

