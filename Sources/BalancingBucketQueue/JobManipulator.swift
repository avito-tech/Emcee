import Foundation
import QueueModels

public protocol JobManipulator {
    func delete(jobId: JobId) throws
}
