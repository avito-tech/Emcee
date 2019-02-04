import Foundation
import Models

public protocol JobManipulator {
    func delete(jobId: JobId) throws
}
